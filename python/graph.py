
class EdgeWeightedGraph:
    """
    Edge weighted graph implementation.
    """
    def __init__(self, V):
        self.V = V
        self.E = -1
        self.graph = []*V

