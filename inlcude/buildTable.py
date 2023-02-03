import networkx as nx
import os

class buildTable():
    """docstring for buildTable."""


    _instance = None

    def __init__(self, tree: nx.DiGraph, values: list) -> None:
        
        self.table = [0] * tree.number_of_nodes()
        self.limiar = [0] * tree.number_of_nodes() 
        self.values = values
        self.tree_name = tree.name

        left_shift = 6
        right_shift = 17
        class_shift = 28
        att_shift = 1


        for node,att in tree.nodes(data=True):

            if tree.out_degree(node) != 0:
                leaf = 0
                neigh = list(tree.neighbors(node))
            else:
                leaf = 1
                neigh = [0,0]

            self.table[node] = (leaf 
                            +( att['att'] << att_shift) 
                            +( neigh[0] << right_shift) 
                            + (neigh[1] << left_shift) 
                            +(att['class_ta'] << class_shift))

            self.limiar[node] = att['th']


    def exportTable(self) -> None:
        
        path =  f"../misc/bench/{self.tree_name}"  
        file_name_tree = f"tree.txt"
        file_name_values = f"values.txt"
        file_name_th = f"th.txt"


        isExist = os.path.exists(path)

        if not isExist:
    
            # Create a new directory because it does not exist 
            os.makedirs(path)
            print("The new directory is created!")

        completeName = os.path.join(path, file_name_tree)
        with open(completeName, 'w') as f:
            for line in self.table:
                print(f'{line}',file = f)

            f.close()

        completeName = os.path.join(path, file_name_values)
        with open(completeName, 'w') as f:
            for line in self.values:
                print(f'{line}',file = f)

            f.close()

        completeName = os.path.join(path, file_name_th)
        with open(completeName, 'w') as f:
            for line in self.limiar:
                print(f'{line}',file = f)

            f.close()


def main():


        tree = nx.DiGraph(name = "tree0")



        th_t = [2.6,1.65,0,0,6.05,2.7,0,5.0,2.55,0,0,0,0]
        att_t = [0,3,0,0,0,1,0,2,1,0,0,0,0]
        class_t = [0,0,0,1,0,0,2,0,0,1,2,1,2]
        values = [2.4,0,0,0,
                  2.7,0,0,2,
                  2.7,0,0,0,
                  7,3,6,0,
                  7,3,4,0,
                  7,2.6,0,0,
                  7,2,0,0]

        for i in range(0,len(th_t)):
            tree.add_node(i,att = att_t[i],class_ta = class_t[i],th = th_t[i])

        tree.add_edge(0,1)
        tree.add_edge(0,2)
        tree.add_edge(1,3)
        tree.add_edge(1,4)
        tree.add_edge(4,5)
        tree.add_edge(4,6)
        tree.add_edge(5,7)
        tree.add_edge(5,8)
        tree.add_edge(7,9)
        tree.add_edge(7,10)
        tree.add_edge(8,11)
        tree.add_edge(8,12)


        t = buildTable(tree,values)



        t.exportTable()


        
        tree = nx.DiGraph(name = "tree1")



        th_t = [2.45,4.95,0,1.7,1.65,0,6.15,0,0,0,0]
        att_t = [2,2,0,3,3,0,0,0,0,0,0]
        class_t = [0,0,0,0,0,1,0,1,2,1,2]
        values = [0,0,2,0,
                  0,0,5,2,
                  0,0,3,2,
                  0,0,3,1,
                  7,0,5,0,
                  0,0,5,0]

        for i in range(0,len(th_t)):
            tree.add_node(i,att = att_t[i],class_ta = class_t[i],th = th_t[i])

        tree.add_edge(0,1)
        tree.add_edge(0,2)
        tree.add_edge(1,3)
        tree.add_edge(1,4)
        tree.add_edge(3,5)
        tree.add_edge(3,6)
        tree.add_edge(4,7)
        tree.add_edge(4,8)
        tree.add_edge(6,9)
        tree.add_edge(6,10)

        t = buildTable(tree,values)



        t.exportTable()


        th_t = [2.45,4.95,0,1.7,1.65,0,6.15,0,0,0,0]
        att_t = [2,2,0,3,3,0,0,0,0,0,0]
        class_t = [0,0,0,0,0,1,0,1,2,1,2]
        values = [0,0,2,0,
                  0,0,5,2,
                  0,0,3,2,
                  0,0,3,1,
                  7,0,5,0,
                  0,0,5,0]

        for i in range(0,len(th_t)):
            tree.add_node(i,att = att_t[i],class_ta = class_t[i],th = th_t[i])

        tree.add_edge(0,1)
        tree.add_edge(0,2)
        tree.add_edge(1,3)
        tree.add_edge(1,4)
        tree.add_edge(3,5)
        tree.add_edge(3,6)
        tree.add_edge(4,7)
        tree.add_edge(4,8)
        tree.add_edge(6,9)
        tree.add_edge(6,10)

        t = buildTable(tree,values)



        t.exportTable()





if __name__ == '__main__':
    main()







        

    
    