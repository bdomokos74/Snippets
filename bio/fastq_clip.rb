#!/usr/bin/env ruby

# Clip n nucleotides from the beginning of each read

require 'optparse'
require 'yaml'
require 'zlib'

class FastqRead 
  attr_accessor :id, :seq
  
  def qual
    @qual
  end
  
  def qual=(qual)
    @qual = qual
    @qual_arr = parse_qual(qual)
  end
  
  def to_s
    @id+"\n"+@seq+"\n+\n"+@qual
  end
  
  def trim_s(n)
    if @seq.size < n
      self.to_s
    else
      @id+"\n"+@seq[0..(n-1)]+"\n+\n"+@qual[0..(n-1)]
    end
  end
  
  def clip_from_start(n)
    subseq = nil
    if @seq.size < n
      raise "Read too short! #{@seq.size}"
    else
      origlen = @seq.size
      @seq = @seq[n..origlen]
      @qual = @qual[n..origlen]
      subseq = @seq[0..(n-1)]
    end
    return subseq
  end
  
  def length
    @seq.size
  end
  
  def has_n?
    $reg_N =~ @seq
  end
  
  def debug(window, qualmin)
    cumsum=get_cumsum(window, qualmin)
    i = get_trim_index(window, qualmin)
    cs = ""
    if i < cumsum.size-1
      cs = cumsum.size.to_s+":["+cumsum[0..(i-1)].join(",")+",<"+cumsum[i].to_s+">,"+cumsum[(i+1)..500].join(",")+"]"
    else
      cs = cumsum.size.to_s+":["+cumsum.join(",")+"]"
    end
    
    @qual_arr.size.to_s+":["+@qual_arr.join(",")+"]\ntrim index:"+i.to_s+"\n"+cs
  end
  
  def parse_qual(qual)
    ret = qual.split('')
    ret.map {|c| c.ord-33}
  end
  
  def get_avg_qual(len)
    sum = @qual_arr[0,len].inject { |acc, val| acc + val}
    sum.to_f/len
  end
  
  def get_cumsum(window, qualmin)
    return 0 if @qual.size<=window
    
    cumsum = Array.new(@qual.size-window+1)
    i = 0
    cumsum[i] = @qual_arr[0, window].inject { |acc, n| acc+n}
    i = 1
    while i<@qual.size-window+1
      cumsum[i] = cumsum[i-1]-@qual_arr[i-1]+@qual_arr[i+window-1]
      i = i + 1
    end
    cumsum
  end

  def get_trim_index(window, qualmin)
    cumsum = get_cumsum(window, qualmin)
    cumsum.index { |sum| sum < qualmin*window } || @seq.size
  end
  
  def self.parseRead(stream)
    tmp = stream.gets
    return nil if tmp.nil?
    tmp.chomp!
    ret = FastqRead.new
    ret.id = tmp
    tmp = stream.gets
    raise "Wrong reads, seq missing, id=#{ret.id}" if tmp.nil?
    ret.seq = tmp.chomp
    tmp = stream.gets
    raise "Wrong reads, + missing id=#{ret.id}" if tmp.nil? || tmp.chomp != "+"
    tmp = stream.gets
    raise "Wrong reads, qual missing id=#{ret.id}" if tmp.nil?
    ret.qual = tmp.chomp
    ret
  end
  
end

##############################

options = {}
optparse = OptionParser.new do |opts|
    opts.banner="Usage: fastq_clip.rb -f <fastq file> -n <number of nucleotides to clip>"
    opts.on('-f', '--fastq FILE', 'fastq file to clip') do |file|
        options[:fastq] = file
    end
    opts.on('-n', '--num NUMBER', 'number of nucleotides to clip from the beginning') do |number|
        options[:number] = number.to_i
    end
    opts.on( '-h', '--help', 'display this screen' ) do
        puts opts
        exit
   end
end

optparse.parse!

if not options[:fastq] or not options[:number]
    puts optparse.help
    exit
end

fastq = nil
if options[:fastq].end_with?(".gz")
  fastq = Zlib::GzipReader.new(File.open(options[:fastq]))
else
  fastq = File.open(options[:fastq], "r")
end

orig_len = 0
clipped_len = 0
r = FastqRead.parseRead(fastq)
stats = Hash.new { |h, k| h[k] = 0 }
until r.nil?
  orig_len += r.length
  clipseq = r.clip_from_start(options[:number])
  clipped_len += r.length
  stats[clipseq] += 1
  puts r
  r = FastqRead.parseRead(fastq)
end
fastq.close()

log = File.open("fastq_clip.log", "a")
log.puts "### #{options[:fastq]}, orig len=#{orig_len}, clipped len=#{clipped_len}, sequence distribution:"
log.puts stats.to_yaml
log.close





