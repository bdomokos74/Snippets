import sys

fname = sys.argv[1]

f = open(fname, 'r')
for line in f:
    arr = line.split()
    chr = arr[0]
    start = int(arr[1])
    end = int(arr[2])
    name = arr[3]
    score = int(float(arr[4]))
    print "%s\t%s\t%s\t%d\t%d\t%d\t%s\t%s\t%s"%(chr, "meta", name, start, end, score, "+", ".", "grp1")
