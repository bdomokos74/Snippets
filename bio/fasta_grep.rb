#!/usr/bin/env ruby

# Read a fasta file and a output the contigs matching to the pattern given as parameter

require 'bio'
require 'optparse'
line_size=70

options = {}
optparse = OptionParser.new do |opts|
    opts.banner="Usage: fasta_grep.rb [-c] [-v] [-f pattern_file]|[pattern] fasta_file"
    opts.on('-f', '--file FILE', 'pattern file (one per line, exact match for contig id)') do |file|
        options[:pattern_file] = file
    end
    opts.on('-c', '--count', 'count matches') do
        options[:count] = true
    end
    opts.on('-v', '--verbose', 'print verbose information') do
        options[:verbose] = true
    end
    opts.on( '-h', '--help', 'display this screen' ) do
        puts opts
        exit
   end
end

optparse.parse!

if ARGV.length==0
    puts optparse.help
    exit
end

contig_hash=Hash.new
if options[:pattern_file]
    file = File.new(options[:pattern_file], "r")
    while (line = file.gets)
        line.strip!
        contig_hash[line] = 1
    end
    file.close
else
    pattern = Regexp.new(ARGV.shift)
end


fasta_file = File.new(ARGV[0])
ff = Bio::FlatFile.new(Bio::FastaFormat, fasta_file)
cnt = 0
ff.each_entry do |f|
    id = f.definition
    first_space_pos = id.index(" ")
    contig = id[0..(first_space_pos-1)]

    if options[:pattern_file]
        next unless contig_hash.member?(contig)
    else
        next unless id =~ pattern
    end

    cnt += 1
    seq = f.naseq

    curr = 0
    len = seq.size

    if not options[:count]
        puts ">#{id}"
        while curr < len
            puts "#{seq[curr..(curr+line_size-1)].upcase}" 
            curr += line_size
        end
    elsif options[:verbose]
        puts "#{contig},#{len}"
    end
end

puts "#{cnt}" if options[:count]

