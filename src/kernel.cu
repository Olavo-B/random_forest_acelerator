#include <cuda_runtime.h>
#include <sys/time.h>
#include <chrono>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>


#define att_mask 0b111110
#define left_mask 0b11111111111000000
#define right_mask 0b1111111111100000000000000000
#define class_mask 0b11110000000000000000000000000000
#define leaf_mask 0b1

#define left_shift 6
#define right_shift 17
#define class_shift 28


#define CHECK(call)                                                            \
{                                                                              \
    const cudaError_t error = call;                                            \
    if (error != cudaSuccess)                                                  \
    {                                                                          \
        fprintf(stderr, "Error: %s:%d, ", __FILE__, __LINE__);                 \
        fprintf(stderr, "code: %d, reason: %s\n", error,                       \
                cudaGetErrorString(error));                                    \
    }                                                                          \
}

void importTable(char *path, int *table)
{
    FILE *fp;
    char *line = NULL;
    size_t len = 0;
    ssize_t read;
    int i =0;

    // printf("Import Tables\n");


    fp = fopen(path, "r");
        if (fp == NULL){
            printf("IMPORT ERRO\n");
            exit(EXIT_FAILURE);

        }

    while ((read = getline(&line, &len, fp)) != -1) {
            // printf("%d\n", atoi(line));
            table[i] = atoi(line);
            i++;
        }

    free(line);

}

void importTH(char *path, float *table)
{
    FILE *fp;
    char *line = NULL;
    size_t len = 0;
    ssize_t read;
    int i =0;


    // printf("Import TH/values\n");


    fp = fopen(path, "r");
        if (fp == NULL){
            printf("IMPORT ERRO\n");
            exit(EXIT_FAILURE);

        }

    while ((read = getline(&line, &len, fp)) != -1) {
            // printf("%f\n", atof(line));
            table[i] = atof(line);
            i++;
        }

    free(line);




}

void printVector(int *vector, int size)
{
    for(int i=0;i<size;i++)
        printf("%d : %d\n",i,vector[i]);
}

void printVectorF(float *vector, int size)
{
    for(int i=0;i<size;i++)
        printf("%d : %.2f\n",i,vector[i]);
}



/*
 * Function:  initialData 
 * --------------------
 * initialize all data using a src as source
 *
 *  dest: vector that will store all final data
 *  src: vecto with data that will be copy to dest
 *  items_n: size of src
 *  copies_n: number of copies of src that will be store in dest
 *
 *  returns: the vector dest filled with copies_n of src
 */
void initialData(float*        dest, 
                  const float*  src, 
                  size_t        items_n,
                  size_t        copies_n)
{
  for(size_t i=0; i<copies_n; i++)
  {
    memcpy(&dest[i * items_n], 
           src, 
           sizeof(*src) * items_n);
  }

    // printf("Inital Data\n");

  
}

void checkResult(int *P,int *proof, int nElem, int nProof){
    
    for(int i=0;i<nElem;i+=nProof){
        for(int j=0;j<nProof;j++){
            assert(P[i+j] == proof[j]);
        }
    }

}

__global__ void table_RF(float *att_table, float *values_table, int *tree_table, int *P, const int N)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int next = 0;
    int atr = 0;
    int left = 0;
    int right = 0;
    float th = 0;

    if(idx < N)
    {

        while((tree_table[next] & leaf_mask) == 0)
        {
            atr = (tree_table[next] & att_mask) >> 1;
            left = (tree_table[next] & left_mask) >> left_shift;
            right = (tree_table[next] & right_mask) >> right_shift;
            th = att_table[next];
            next = (values_table[(4*idx)+atr] > th ? right:left);


        }

    
        P[idx] = (tree_table[next] & class_mask) >> class_shift;

    }



}


int main()
{

    float elapsed_time;
    char path[] = "/home/olavo/random_forest_acelerator/misc/bench/tree0/tree.txt";
    char path_th[] = "/home/olavo/random_forest_acelerator/misc/bench/tree0/th.txt";
    char path_values[] = "/home/olavo/random_forest_acelerator/misc/bench/tree0/values.txt";

    int dev = 0;
    cudaDeviceProp deviceProp;
    CHECK(cudaGetDeviceProperties(&deviceProp, dev));
    printf("Using Device %d: %s\n", dev, deviceProp.name);
    CHECK(cudaSetDevice(dev));

    int nElem = 1 << 20;
    int nThreads = 7;
    int nBlocks = 1;
    int nBytes = nElem * sizeof(float);
    int *tree_table,*P;
    float *att_table,*values,*values_copy;

    att_table     = (float *)malloc(nBytes);
    values     = (float *)malloc(nBytes);
    values_copy     = (float *)malloc(28 * sizeof(float));
    tree_table  = (int *)malloc(nBytes);
    P  = (int *)malloc(nBytes);

    printf("Number of elements: %d\n",nElem);

    importTable(path,tree_table);
    importTH(path_th,att_table);
    importTH(path_values,values_copy);

    initialData(values,values_copy,28,nElem/28);

    

    float *d_values, *d_att;
    int *d_table,*d_P;
    CHECK(cudaMalloc((float**)&d_values, nBytes));
    CHECK(cudaMalloc((float**)&d_att, nBytes));
    CHECK(cudaMalloc((int**)&d_P, nBytes));
    CHECK(cudaMalloc((int**)&d_table, nBytes));



    // transfer data from host to device
    CHECK(cudaMemcpy(d_att, att_table, nBytes, cudaMemcpyHostToDevice));
    CHECK(cudaMemcpy(d_values, values, nBytes, cudaMemcpyHostToDevice));
    CHECK(cudaMemcpy(d_table, tree_table, nBytes, cudaMemcpyHostToDevice));

    // invoke kernel at host side
    int iLen = 512;
    dim3 block (iLen);
    dim3 grid  ((nElem + block.x - 1) / block.x);

    cudaEvent_t start, stop;
    CHECK(cudaEventCreate(&start));
    CHECK(cudaEventCreate(&stop));

     //Código GPU
    // record start event
    CHECK(cudaEventRecord(start, 0));   
    table_RF<<<nElem/nThreads, nBlocks>>>(d_att, d_values, d_table,d_P,nElem);
    CHECK(cudaEventRecord(stop, 0));
    CHECK(cudaEventSynchronize(stop));
    // calculate elapsed time
    CHECK(cudaEventElapsedTime(&elapsed_time, start, stop));
    printf("RF with TABLE - execution time = %.6fms\n",
           elapsed_time );

    CHECK(cudaGetLastError());
    
    // copy kernel result back to host side
    CHECK(cudaMemcpy(P, d_P, nBytes, cudaMemcpyDeviceToHost));


    /* Check results*/
    int proof[7] = {0,1,2,1,2,1,2};
    checkResult(P,proof,((nElem/nThreads)-3),7);

    /* Free all memory*/
    CHECK(cudaFree(d_att));
    CHECK(cudaFree(d_values));
    CHECK(cudaFree(d_table));
    CHECK(cudaFree(d_P));

    free(tree_table);
    free(values);
    free(values_copy);
    free(att_table);
    free(P);




    return 0;
    
}