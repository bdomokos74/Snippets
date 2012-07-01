package org.bali.algoclass;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.util.ArrayList;

/**
 * User: bds
 * 28/06/2012 22:36
 */
public class QuickSort {
    private long cmpCount;

    public static void main(String[] args) throws Exception{
        BufferedReader br = new BufferedReader(new FileReader("QuickSort.txt"));
        String line;
        ArrayList<String> inputStr = new ArrayList<String>();
        while ((line = br.readLine()) != null) {
            inputStr.add(line);
        }
        br.close();
        int n = inputStr.size();
        System.out.println("Input size="+n);
        int input[] = new int[n];
        for (int i = 0; i < n; i++) {
            input[i] = Integer.parseInt(inputStr.get(i));
        }

        QuickSort qs = new QuickSort();
        qs.sort1(input, 0, 10000);
        System.out.println("Result: "+qs.getCmpCount());

        BufferedWriter bw = new BufferedWriter(new FileWriter("result.txt"));
        for (int i = 0; i < input.length; i++) {
            bw.write(String.valueOf(input[i]));
            bw.newLine();
        }
        bw.close();
    }

    public QuickSort() {
        cmpCount = 0;
    }

    public long getCmpCount() {
        return cmpCount;
    }

    void sort1(int[] input, int l, int r) {
        if(l>=r-1) return;
        // pivot: first, do nothing... chg=162085

        // pivot: last, chg = 164123
        //int tmp = input[l];
        //input[l] = input[r - 1];
        //input[r-1] = tmp;
        
        // pivot: median of 3, chg=138382
        int a = input[l];
        int medianPos = (r-l)/2;
        if((l-r)%2==0) medianPos--;
        medianPos+=l;
        System.out.println("l,r="+l+","+r+" medianpos="+medianPos);
        int b = input[medianPos];
        int c = input[r - 1];
        if ((b < a && a < c) || (c < a && a < b)) {
            // do nothing
        } else if ((a < c && c < b) || (b < c && c < a)) {
            int tmp = input[l];
            input[l] = input[r - 1];
            input[r-1] = tmp;
        } else if ((a < b && b < c) || (c < b && b < a)) {
            int tmp = input[l];
            input[l] = input[medianPos];
            input[medianPos] = tmp;
        } else {
            System.out.println("len2, a,b,c="+a+ ","+b+","+c+" l,r="+l+","+r);
        }
        int pivotPos = partition(input, l, r);
        sort1(input, l, pivotPos);
        sort1(input, pivotPos + 1, r);
    }

    // 162085
    int partition(int A[], int l, int r) {
        cmpCount += (r-l-1);
        int p = A[l];
        int i = l+1;
        for (int j = l + 1; j < r; j++) {
            if (A[j] < p) {
                int tmp = A[i];
                A[i] = A[j];
                A[j] = tmp;
                i++;
            }
        }
        int tmp = A[l];
        A[l] = A[i - 1];
        A[i-1] = tmp;
        return (i-1);
    }
}
