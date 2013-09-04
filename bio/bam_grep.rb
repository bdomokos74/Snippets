#!/usr/bin/env ruby

# Select specific alignments from a fastq file, matching different patterns. Reads the standard input for SAM format data,
# use samtools -h file.bam |fastq_grep.rb ... 

require 'optparse'
require 'yaml'
require 'zlib'

class BamRead
  attr_accessor :read, :hdr, :id

  def self.parseRead(stream)
    tmp = stream.gets
    return nil if tmp.nil?
    tmp.chomp!
    ret = BamRead.new
    if tmp.start_with?("@")
      ret.hdr = tmp
      if tmp.start_with?("@SQ")
        i1 = tmp.index(":")
        i2 = tmp.index("\t", i1+1)
        ret.id = tmp[i1+1, i2-i1-1]
      end
      return ret
    end
    ret.read = tmp
    i1 = tmp.index("\t")
    i2 = tmp.index("\t", i1+1)
    i3 = tmp.index("\t", i2+1)
    ret.id = tmp[i2+1, i3-i2-1]
    ret
  end
  
  def hdr?
    not hdr.nil?
  end
  
  def to_s
    if not hdr?
      @read
    else
      @hdr
    end
  end
  
  def qual
    @qual
  end
  
  def qual=(qual)
    @qual = qual
    @qual_arr = parse_qual(qual)
  end
  
  def matching?(contig_list)
     contig_list.each do |contig|
       if hdr? and (not hdr.start_with?("@SQ") or id == contig)
         return true
       elsif id == contig
         return true
       end
     end
     return false
  end
  
end

require 'optparse'
line_size=70

options = {}
optparse = OptionParser.new do |opts|
    opts.banner="Usage: bam_grep.rb [-f pattern_file]|[pattern]"
    opts.on('-f', '--file FILE', 'pattern file (one per line, exact match for contig id)') do |file|
        options[:pattern_file] = file
    end
    opts.on( '-h', '--help', 'display this screen' ) do
        puts opts
        exit
   end
end

optparse.parse!

contig_list=[]
if options[:pattern_file]
    file = File.new(options[:pattern_file], "r")
    while (line = file.gets)
        line.strip!
        contig_list << line
    end
    file.close
else
    contig_list << ARGV.shift
end

r = BamRead.parseRead(ARGF)
until r.nil?
  if r.matching?(contig_list)
    puts r
  end
  r = BamRead.parseRead(ARGF)
end








