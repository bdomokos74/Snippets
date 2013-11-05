from graph import *
import unittest

class TestEdgeWeightedGraph(unittest.TestCase):
    def setUp(self):
        self.g = EdgeWeightedGraph(10)

        self.g.add_edge(Edge(0,1))
        self.g.add_edge(Edge(2,3))
        self.g.add_edge(Edge(4,5))
        self.g.add_edge(Edge(5,6))
        self.g.add_edge(Edge(6,4))
        self.g.add_edge(Edge(6,7))
        self.g.add_edge(Edge(8,9))
        #g.write_gv(datadir+"/"+"test"+"_graph.gv.txt")

    def testEdges(self):
        edges = self.g.edges()
        for e in edges:
            print e.to_str()

if __name__ == "__main__":
    unittest.main()
