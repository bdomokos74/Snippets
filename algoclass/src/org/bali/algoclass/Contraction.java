package org.bali.algoclass;

import java.io.*;
import java.util.*;

/**
 * User: bds
 * 29/06/2012 22:49
 */
public class Contraction {
    static class Graph {
        int N;
        int graph[][];
        int lengths[];
        int nEdges;
        int nVertices;

        public static Graph parse(ArrayList<String> lines) {
            Graph g = new Graph();
            int N = lines.size();
            g.N = N;
            g.graph = new int[N][100*N];
            g.lengths = new int[N];
            for (int i = 0; i < N; i++) {
                for (int j = 0; j < N; j++) {
                    g.graph[i][j] = -1;
                }
                g.lengths[i] = 0;
            }
            g.nEdges = 0;
            g.nVertices = N;
            for (String line : lines) {
                String parts[] = line.split("\\s+");
                if (parts.length == 1) {
                    continue;
                }
                int currId = Integer.parseInt(parts[0])-1;
                g.lengths[currId] = parts.length-1;
                for (int i = 1; i < parts.length; i++) {
                    int otherId = Integer.parseInt(parts[i])-1;
                    g.graph[currId][i - 1] = otherId;
                    g.nEdges++;
                }
            }
            return g;
        }
        
        @Override
        public String toString() {
            StringBuilder b = new StringBuilder();
            b.append("N="+N+" nVertices="+nVertices+" nEdges="+nEdges).append('\n');
            for (int i = 0; i < N; i++) {
                b.append(i).append(" - ");
                for (int j = 0; j < lengths[i]; j++) {
                    b.append(graph[i][j]).append(" ");
                }
                b.append(" | " + lengths[i]).append('\n');
            }
            return b.toString();
        }

        void drawState(int step) throws Exception{
            StringBuilder b = new StringBuilder();
            HashSet<String> skip = new HashSet<String>();
            b.append("Graph g {\n\toverlap=\"false\";\n");
            for (int i = 0; i < N; i++) {
                for (int j = 0; j < lengths[i]; j++) {
                    int k = graph[i][j];
                    if(skip.contains(""+i+"_"+k)) continue;
                    skip.add(""+k+"_"+i);
                    b.append("\t\"").append(i).append("\" -- \"").append(graph[i][j]).append("\"\n");
                }
            }
            b.append("}\n");
            BufferedWriter w = new BufferedWriter(new FileWriter("tmp/graph"+step+".gv"));
            w.write(b.toString());
            w.close();

            String cmd = "/usr/local/bin/neato -v -Tpng tmp/graph"+step+".gv -o tmp/graph"+step+".png" ;
            Runtime run = Runtime.getRuntime() ;
            Process pr = run.exec(cmd) ;
            int exitVal = pr.waitFor();
            BufferedReader buf = new BufferedReader(new InputStreamReader(pr.getInputStream()));
            String line = "";
            while ((line=buf.readLine())!=null) {
            }
            new File("tmp/graph"+step+".gv").delete();
        }
    }
    
    static class Algo {
        boolean debug;

        Algo(boolean debug) {
            this.debug = debug;
        }
        Algo() {
            this(false);
        }
        int contract(Graph g) throws Exception {
            if(debug) System.out.println(g);
            int step=1;
            Random rnd = new Random(new Date().getTime());
            while (g.nVertices!=2) {
                StringBuilder sb = new StringBuilder();
                sb.append("step ").append(step).append(". ");
                if(debug) g.drawState(step++);
                int keptVertex = 0;
                int currIndex = rnd.nextInt(g.nEdges);
                while (g.lengths[keptVertex] <= currIndex) {
                    currIndex -= g.lengths[keptVertex];
                    keptVertex++;
                }
                int vertexToContract = g.graph[keptVertex][currIndex];
                sb.append(vertexToContract).append(" -> ").append(keptVertex).append(", vertices:").
                        append(g.nVertices).append(" edges:").append(g.nEdges);
                if(debug) System.out.println(sb.toString());
                
                for (int i = 0; i < g.lengths[vertexToContract]; i++) {
                    g.graph[keptVertex][g.lengths[keptVertex] + i] = g.graph[vertexToContract][i];
                    g.graph[vertexToContract][i] = -2;
                }
                g.lengths[keptVertex] += g.lengths[vertexToContract];

                for (int i = 0; i < g.N; i++) {
                    for (int j = 0; j < g.lengths[i]; j++) {
                        if(g.graph[i][j]==vertexToContract) {
                            g.graph[i][j] = keptVertex;
                        }
                    }
                }

                int k = keptVertex;
                int i = 0;
                int j = 0;
                int nRemoved = 0;
                while(j<g.lengths[k]) {
                    if (g.graph[k][i] != k) {
                        i++;
                        if (j < i) j = i;
                    } else {
                        while (g.graph[k][j] == k && j<g.lengths[k]) {
                            nRemoved ++;
                            j++;
                        }
                        if (j < g.lengths[k]) {
                            g.graph[k][i] = g.graph[k][j];
                            g.graph[k][j] = k;
                            j++;
                            i++;
                        }
                    }
                }
                g.lengths[k] -= nRemoved;
                g.nEdges -= nRemoved;
                g.lengths[vertexToContract] = 0;
                g.nVertices--;
            }
            int i = 0;

            StringBuilder sb = new StringBuilder();
            while (g.lengths[i] == 0) {
                i++;
            }
            if(debug) g.drawState(step++);
            sb.append("step ").append(step).append(". vertices:").append(g.nVertices).append(" edges:").append(g.nEdges).
                    append(" i:").append(i).append( " len(i):").append(g.lengths[i]).append(" [");
            for (int j = 0; j < g.lengths[i]; j++) {
                sb.append(g.graph[i][j]).append(' ');
            }
            sb.append(']');
            if(debug) System.out.println(sb.toString());
            return g.lengths[i];
        }
    }
    
    static final int iter = 2000;
    public static void main(String[] args) throws Exception{
        BufferedReader br = new BufferedReader(new FileReader("kargerMinCut.txt"));
        ArrayList<String> lines = new ArrayList<String>();
        String line;
        while ((line = br.readLine()) != null) {
            lines.add(line);
        }
        br.close();
        
        int result = Integer.MAX_VALUE;
        int count = 0;
        for(int i = 0; i<iter; i++) {
            Graph g = Graph.parse(lines);
            Algo algo = new Algo();
            
            int curr = algo.contract(g);
            if (result > curr) {
                result = curr;
                count = 0;
            }
            if (result == curr) {
                count++;
            }
        }
        System.out.println("result: "+result+" count: "+count);
    }

}
