#!/usr/bin/env ruby
#
require 'bio'

def printUsage(str)
	puts str
	puts "Usage: fasta_extract_region -c <contig> [-a]|[-s <start_positions> -l <lengths>] <input.fasta>"
end

line_size = 70

tmp = ARGV.shift
if tmp!="-c"
	printUsage("Missing -c")
	exit
end
contig = ARGV.shift

all = false
tmp = ARGV.shift
if tmp=="-a"
	all = true
else
	if tmp!="-s"
		printUsage("Missing -s")
		exit
	end
	startPos = ARGV.shift
	startPos = startPos.split(',').map{ |s| s.to_i }

	tmp = ARGV.shift
	if tmp!="-l"
		printUsage("Missing -l")
		exit
	end

	lengths = ARGV.shift
	lengths = lengths.split(',').map{ |s| s.to_i }
end

fasta = ARGV.shift

$stderr.puts ("Opening #{fasta}")

fasta = File.new(fasta, "r")
ff = Bio::FlatFile.new(Bio::FastaFormat, fasta)
found = false
result = ""
ff.each_entry do |f|
	id = f.definition
	idx = id.index(" ")
	id = id[0..(idx-1)]

	if id==contig
		seq = f.naseq
		if all
			result = seq		
		else
			regions = startPos.each_with_index.map { |start, i|
				seq[start..(start+lengths[i]-1)]
			}
			result = regions.join
		end
		found = true
		curr = 0
		len = result.size
		puts ">#{id}"
    while curr < len
        puts "#{result[curr..(curr+line_size-1)].upcase}" 
        curr += line_size
    end
		break
	end
end

$stderr.puts "Contig not found" if not found
