#!/usr/bin/env ruby

require 'bio'

line_size = 70

ff = Bio::FlatFile.new(Bio::FastaFormat, ARGF)
ff.each_entry do |f|
  id = f.definition
  seq = f.naseq
  revseq = seq.reverse_complement.upcase
  len = revseq.size
  puts ">#{id}"
  curr=0
  while curr < len
      puts "#{revseq[curr..(curr+line_size-1)]}" 
      curr += line_size
  end
end
