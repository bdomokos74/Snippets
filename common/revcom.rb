#!/usr/bin/env ruby

require 'bio'

ff = Bio::FlatFile.new(Bio::FastaFormat, ARGF)
ff.each_entry do |f|
  seq = f.naseq
  puts "#{seq.reverse_complement.upcase}"
end
