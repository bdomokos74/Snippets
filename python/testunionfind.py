from unionfind2 import *
import unittest

class TestUnionFind(unittest.TestCase):
    def setUp(self):
        self.uf = UnionFind(10)

    def testUnion(self):
        self.assertEqual(self.uf.count(), 10)
        self.uf.union(1,2)
        self.assertEqual(self.uf.count(), 9)
        self.assertEqual(self.uf.connected(1,2), True)
        self.uf.union(2,3)
        self.assertEqual(self.uf.count(), 8)
        self.assertEqual(self.uf.connected(1,3), True)
        self.assertEqual(self.uf.connected(1,4), False)
        self.uf.union(4,5)
        self.assertEqual(self.uf.count(), 7)
        self.assertEqual(self.uf.connected(1,4), False)
        self.assertEqual(self.uf.connected(5,4), True)

        print self.uf.count()

if __name__ == "__main__":
    unittest.main()
