#!/usr/bin/env ruby

# Trim and filter paired fastq files to generate _trimmed.fastq with valid pairs and _singleton.fastq with reads of which the pair got filtered.
# This tool should be run after examining quality metrics e.g. using FastqC.

require 'optparse'
require 'yaml'
require 'zlib'

$reg_N = Regexp.new('N')

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
    opts.banner="Usage: fastq_trim.rb -1 <fastq1 file> -2 <fastq 2 file> -o <output_prefix> [-w <window size>] [-q <quality threshold>] [-l <min length>]"
    opts.on('-1', '--fastq1 FILE', 'fastq file with first mate') do |file|
        options[:fastq1] = file
    end
    opts.on('-2', '--fastq2 FILE', 'fastq file with second mate') do |file|
        options[:fastq2] = file
    end
    opts.on('-o', '--output PREFIX', 'output file prefix') do |prefix|
        options[:prefix] = prefix
    end
    options[:window] = 10
    opts.on('-w', '--window [WINDOW]', 'window size for quality average') do |window|
        options[:window] = window.to_i
    end
    options[:qual] = 20
    opts.on('-q', '--qual-min [QUAL]', 'minimum quality') do |qual|
        options[:qual] = qual.to_i
    end
    options[:minlen] = 50
    opts.on('-l', '--length-min [LEN]', 'minimum length after trimming') do |len|
        options[:minlen] = len.to_i
    end
    opts.on('-t', '--test', 'test') do
        options[:test] = true
    end
    opts.on( '-h', '--help', 'display this screen' ) do
        puts opts
        exit
   end
end

optparse.parse!

if not options[:fastq1] or not options[:fastq2] or not options[:window] or not options[:qual]
    puts optparse.help
    exit
end

if not File.exist?(options[:fastq1])
  puts "Input file #{options[:fastq1]} does not exist.\n\n"
  puts optparse.help
  exit
end

if not File.exist?(options[:fastq2])
  puts "Input file #{options[:fastq2]} does not exist.\n\n"
  puts optparse.help
  exit
end

unless options[:fastq1].end_with?(".fastq") or options[:fastq1].end_with?(".fastq.gz")
  puts "Input file #{options[:fastq1]} needs to have extension .fastq[.gz]\n\n"
  puts optparse.help
  exit
end

unless options[:fastq2].end_with?(".fastq") or options[:fastq2].end_with?(".fastq.gz")
  puts "Input file #{options[:fastq2]} needs to have extension .fastq[.gz]\n\n"
  puts optparse.help
  exit
end

# if ARGV.length==0
#     puts optparse.help
#     exit
# end

puts "Processing: #{options[:fastq1]} ; #{options[:fastq2]}"
puts "Output prefix: #{options[:prefix]}"
puts "Window: #{options[:window]}, min qual: #{options[:qual]}, min lenght: #{options[:minlen]}"
puts "_______________________\nReading input files...\n"

fastq1 = nil
if options[:fastq1].end_with?(".gz")
  fastq1 = Zlib::GzipReader.new(File.open(options[:fastq1]))
else
  fastq1 = File.open(options[:fastq1], "r")
end
fastq2 = nil
if options[:fastq2].end_with?(".gz")
  fastq2 = Zlib::GzipReader.new(File.open(options[:fastq2]))
else
  fastq2 = File.open(options[:fastq2], "r")
end

if options[:test]
  r1 = FastqRead.parseRead(fastq1)
  r2 = FastqRead.parseRead(fastq2)
  puts "Read 1:"
  puts r1
  puts r1.debug(options[:window], options[:qual])
  puts r1.trim_s(r1.get_trim_index(options[:window], options[:qual]))
  
  puts "Read 2:"
  puts r2
  puts r2.debug(options[:window], options[:qual])
  puts r2.trim_s(r2.get_trim_index(options[:window], options[:qual]))
else
  trname1 = options[:prefix]+"_1_trimmed.fastq"
  trname2 = options[:prefix]+"_2_trimmed.fastq"
  singlename = options[:prefix]+"_singleton.fastq"
  tr1 = File.open(trname1, "w")
  tr2 = File.open(trname2, "w")
  single = File.open(singlename, "w")
  
  r1 = FastqRead.parseRead(fastq1)
  r2 = FastqRead.parseRead(fastq2)
  stats = Hash.new { |h, k| h[k] = 0 }
  stats[:avg_qual] = 0.0
  until r1.nil? and r2.nil?
    stats[:r1_all] += 1 unless r1.nil?
    stats[:r2_all] += 1 unless r2.nil?
    r1_skip = r1.nil? || r1.has_n?
    r2_skip = r2.nil? || r2.has_n?

    trim_index_1 = 0
    trim_index_2 = 0
    if not r1_skip
      trim_index_1 = r1.get_trim_index(options[:window], options[:qual])
      r1_skip = true if trim_index_1 <= options[:minlen]
    end
    if not r2_skip
      trim_index_2 = r2.get_trim_index(options[:window], options[:qual])
      r2_skip = true if trim_index_2 <= options[:minlen]
    end
    
    if r1_skip and r2_skip
      #do nothing...
      stats[:r1_skip] += 1
      stats[:r2_skip] += 1
    elsif r1_skip and not r2_skip
      stats[:r1_skip] += 1
      stats[:singletons] += 1
      stats[:trimmed] += 1 if trim_index_2 < r2.length
      stats[:bases] += trim_index_2
      stats[:avg_qual] += r2.get_avg_qual(trim_index_2)
      single.puts r2.trim_s(trim_index_2)
    elsif not r1_skip and r2_skip
      stats[:r2_skip] += 1
      stats[:singletons] += 1
      stats[:trimmed] += 1 if trim_index_1 < r1.length
      stats[:bases] += trim_index_1
      stats[:avg_qual] += r1.get_avg_qual(trim_index_1)
      single.puts r1.trim_s(trim_index_1)
    else
      stats[:pairs] += 1
      stats[:trimmed] += 1 if trim_index_1 < r1.length
      stats[:trimmed] += 1 if trim_index_2 < r2.length
      stats[:bases] += trim_index_1
      stats[:bases] += trim_index_2
      stats[:avg_qual] += r1.get_avg_qual(trim_index_1)
      stats[:avg_qual] += r2.get_avg_qual(trim_index_2)
      tr1.puts r1.trim_s(trim_index_1)
      tr2.puts r2.trim_s(trim_index_2)
    end
    
    r1 = FastqRead.parseRead(fastq1) unless r1.nil?
    r2 = FastqRead.parseRead(fastq2) unless r2.nil?
  end
  
  tr1.close
  tr2.close
  single.close
  
  puts stats.to_yaml
  reads_ok = stats[:pairs]*2+stats[:singletons]
  puts "avg qual: #{stats[:avg_qual].to_f/reads_ok}"
  puts "avg readlen: #{stats[:bases].to_f/reads_ok}"
end

fastq1.close
fastq2.close

