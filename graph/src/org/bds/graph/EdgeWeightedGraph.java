package org.bds.graph;

import java.io.*;
import java.util.LinkedList;

/**
 * User: bds
 * Date: 9/4/13
 */
public class EdgeWeightedGraph {
    private int V;
    private int E;
    private LinkedList<Edge>[] graph;

    public EdgeWeightedGraph(int nV) {
        V = nV;
        graph = (LinkedList<Edge>[])new LinkedList[nV];
        for (int i = 0; i < nV; i++) {
            graph[i] = new LinkedList<Edge>();
        }
    }

    public EdgeWeightedGraph(InputStream is) throws IOException {
        // One based indexes in file!
        BufferedReader dis = new BufferedReader(new InputStreamReader(is));
        String line = dis.readLine();
        String arr[] = line.split("\\s+");
        V = Integer.parseInt(arr[0]);

        graph = (LinkedList<Edge>[])new LinkedList[V];
        for (int i = 0; i < V; i++) {
            graph[i] = new LinkedList<Edge>();
        }

        int tempE = Integer.parseInt(arr[1]);
        for (int i = 0; i < tempE; i++) {
            line = dis.readLine();
            arr = line.split("\\s+");
            int x = Integer.parseInt(arr[0])-1;
            int y = Integer.parseInt(arr[1])-1;
            double d = Double.parseDouble(arr[2]);
            addEdge(new Edge(x, y, d));
        }
    }

    public int V() {
        return V;
    }

    public int E() {
        return E;
    }

    public void addEdge(Edge e) {
        int i = e.either();
        int j = e.other(i);
        graph[i].add(e);
        graph[j].add(e);
        E++;
    }

    public Iterable<Edge> adj(int v) {
        return graph[v];
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append(V).append(" vertices, ").append(E).append(" edges\n");
        for (int v = 0; v < V; v++) {
            sb.append(v).append(": ");
            for (Edge e : adj(v)) {
                sb.append("[").append(e).append("] ");
            }
            sb.append("\n");
        }
        return sb.toString();
    }
}

