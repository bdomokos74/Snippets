package org.bds.graph;

/**
 * User: bds
 * Date: 9/4/13
 */
public class Edge {
    private final int i;
    private final int j;
    private final double w;

    public Edge(int i, int j, double w) {
        this.i = i;
        this.j = j;
        this.w = w;
    }

    public int either() {
        return i;
    }

    public int other(int e) {
        if (e == i) {
            return j;
        } else if (e == j) {
            return i;
        }
        throw new RuntimeException("Inconsistent edge call");
    }

    public double weight() {
        return w;
    }

    public int compareTo(Edge e) {
        if (this.w < e.weight()) {
            return -1;
        } else if (this.w > e.weight()) {
            return 1;
        } else {
            return 0;
        }
    }

    public String toString() {
        return String.format("%d-%d %.2f", i, j, w);
    }
}
