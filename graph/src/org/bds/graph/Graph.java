package org.bds.graph;

import java.io.DataInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.LinkedList;

/**
 * User: bds
 * Date: 9/4/13
 */
public class Graph {
    private int V;
    private int E;
    private LinkedList<Integer>[] graph;

    public Graph(int nV) {
        V = nV;
        graph = (LinkedList<Integer>[])new LinkedList[nV];
        for (int i = 0; i < nV; i++) {
            graph[i] = new LinkedList<Integer>();
        }
    }

    public Graph(InputStream is) throws IOException {
        DataInputStream dis = new DataInputStream(is);
        V = dis.readInt();

        graph = (LinkedList<Integer>[])new LinkedList[V];
        for (int i = 0; i < V; i++) {
            graph[i] = new LinkedList<Integer>();
        }

        int tempE = dis.readInt();
        for (int i = 0; i < tempE; i++) {
            int x = dis.readInt();
            int y = dis.readInt();
            addEdge(x, y);
        }
    }

    public int V() {
        return V;
    }

    public int E() {
        return E;
    }

    public void addEdge(int i, int j) {
        graph[i].add(j);
        graph[j].add(i);
        E++;
    }

    public Iterable<Integer> adj(int v) {
        return graph[v];
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append(V).append(" vertices, ").append(E).append(" edges\n");
        for (int v = 0; v < V; v++) {
            sb.append(v).append(": ");
            for (int w : adj(v)) {
                sb.append(w).append(" ");
            }
            sb.append("\n");
        }
        return sb.toString();
    }
}

