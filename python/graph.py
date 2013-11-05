import re

class Edge:
    def __init__(self, i, j):
        self.i = i
        self.j = j
        self.attr = {}
        self.weight = 0.0

    def either(self):
        return self.i

    def other(self, n):
        if self.i == n:
            return self.j
        return self.i

    def to_str(self):
        return "%d - %d %.2f"%(self.i, self.j, self.weight)

class Vertex:
    def __init__(self, id):
        self.id = id
        self.attr = {}
        self.edges = []

    def add_edge(self, edge):
        self.edges.append(edge)

class EdgeWeightedGraph:
    """
    Edge weighted graph implementation.
    """
    def __init__(self, V):
        self.V = V
        self.E = 0
        self.graph = [ Vertex(i) for i in range(V) ]
        self._x = None

    @staticmethod
    def readFile(fname):
        f = open(fname, 'r')
        linenum = 0
        for line in f:
            if linenum==0:
                g = EdgeWeightedGraph(int(line.strip()))
            else:
                arr = re.split("\s+", line.strip())
                e = Edge(int(arr[0])-1, int(arr[1])-1)
                e.weight = float(arr[2])
                g.add_edge(e)
            linenum +=1
        f.close()
        return(g)

    def add_edge(self, edge):
        i = edge.either()
        j = edge.other(i)
        self.graph[i].add_edge( edge )
        self.graph[j].add_edge( edge )
        self.E += 1

    def adj(self, i):
        return self.graph[i].edges

    def to_str(self):
        result = "%d vertices, %d edges\n"%(self.V, self.E)
        for v in range(self.V):
            result += str(v)
            result += str(self.attr(v))
            result += ": "
            for e in self.adj(v):
                result += "[" + e.to_str()+"] "
            result += "\n"
        return result


    def attr(self, v):
        return self.graph[v].attr

    def set_attr(self, v, value):
        self.graph[v].attr = value

    def edges(self):
        result = []
        for v in range(self.V):
            for e in self.adj(v):
                if e.other(v)>v:
                    result.append(e)
        return( result)

    # Writes graphwiz dot format file. Generate drawing as follows (if the filename is test.gv.txt):
    # neato -Tpdf test.gv.txt -o testgraph.pdf
    def write_gv(self, fname):
        f = open(fname, 'w')
        f.write("graph G {\n")
        visited = set()
        for v in range(self.V):
            for e in self.adj(v):
                if not (e in visited):
                    visited.add(e)
                    i = e.either()
                    j = e.other(i)
                    f.write("\t%d -- %d;\n"%(i, j))
        f.write("}\n")
        f.close()

class Divertex:
    def __init__(self, id):
        self.id = id
        self.attr = {}
        self.edges = []
        self.inedges = []

    def add_edge(self, edge):
        self.edges.append(edge)

    def add_inedge(self, edge):
        self.inedges.append(edge)

class EdgeWeightedDigraph:
    """
    Edge weighted graph implementation.
    """
    def __init__(self, V):
        self.V = V
        self.E = 0
        self.graph = [ Divertex(i) for i in range(V) ]
        self._x = None

    @staticmethod
    def readFile(fname):
        f = open(fname, 'r')
        linenum = 0
        for line in f:
            if linenum==0:
                g = EdgeWeightedDigraph(int(re.split("\s+", line.strip())[0]))
            else:
                arr = re.split("\s+", line.strip())
                e = Edge(int(arr[0])-1, int(arr[1])-1)
                e.weight = float(arr[2])
                g.add_edge(e)
            linenum +=1
        f.close()
        return(g)

    def add_edge(self, edge):
        self.graph[edge.i].add_edge( edge )
        self.graph[edge.j].add_inedge(edge)
        self.E += 1

    def adj(self, i):
        return self.graph[i].edges

    def inedges(self, i):
        return self.graph[i].inedges

    def to_str(self):
        result = "%d vertices, %d edges\n"%(self.V, self.E)
        for v in range(self.V):
            result += str(v)
            result += str(self.attr(v))
            result += ": "
            for e in self.adj(v):
                result += "[" + e.to_str()+"] "
            result += "\n"
        return result


    def attr(self, v):
        return self.graph[v].attr

    def set_attr(self, v, value):
        self.graph[v].attr = value

    def edges(self):
        result = []
        for v in range(self.V):
            for e in self.adj(v):
                result.append(e)
        return( result)

    # Writes graphwiz dot format file. Generate drawing as follows (if the filename is test.gv.txt):
    # neato -Tpdf test.gv.txt -o testgraph.pdf
    def write_gv(self, fname):
        f = open(fname, 'w')
        f.write("digraph G {\n")
        visited = set()
        for v in range(self.V):
            for e in self.adj(v):
                if not (e in visited):
                    visited.add(e)
                    i = e.either()
                    j = e.other(i)
                    f.write("\t%d -> %d [len=%f];\n"%(i, j, (e.weight)))
        f.write("}\n")
        f.close()

def main():
    print "testing graph"
    g = EdgeWeightedGraph(5)
    g.set_attr(2, {"bac": "neisseria", "id": "0", "orientation": "LR"})
    g.add_edge( Edge(0,1))
    g.add_edge( Edge(2,3))
    g.add_edge( Edge(3,4))
    g.add_edge( Edge(4,2))
    g.write_gv("test.gv.txt")
    print g.to_str()

if __name__ == "__main__":
    main()

