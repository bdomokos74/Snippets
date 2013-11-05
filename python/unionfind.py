
class UnionFind:
    def __init__(self, N):
        self.N = N
        self.arr = [i for i in range(N)]
        self.counts = [1]*N
        self.component_num = N

    def union(self, p, q):
        pId = self.find(p)
        qId = self.find(q)
        # print self.arr
        # print self.counts
        if pId==qId:
            return

        for k in range(self.N):
            if self.arr[k] == pId:
                self.arr[k] = qId
        self.component_num = self.component_num-1
        # print self.arr
        # print "---"

    def find(self, i):
        return(self.arr[i])

    def connected(self, i, j):
        return(self.find(i)==self.find(j))

    def count(self):
        return(self.component_num)

    def printarr(self):
        print self.arr