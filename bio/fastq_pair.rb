#!/usr/bin/env ruby

# Sort two fastq files of a paired sequencing: take the 1st one as the reference order, and output both with matching ids 
# of the first file. Output statistics of the result.

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
  
  def get_key
    ind = @id.index(" ")
    @id[0..(ind-1)]
  end
end

##############################

options = {}
optparse = OptionParser.new do |opts|
    opts.banner="Usage: fastq_sort.rb -1 <fastq file 1> -2 <fastq file 2> -p <output prefix>"
    opts.on('-1', '--fastq1 FILE', 'fastq file 1 to clip') do |file|
        options[:fastq1] = file
    end
    opts.on('-2', '--fastq2 FILE', 'fastq file 2 to clip') do |file|
        options[:fastq2] = file
    end
    opts.on('-p', '--prefix PREFIX', 'output prefix') do |prefix|
        options[:prefix] = prefix
    end
    opts.on( '-h', '--help', 'display this screen' ) do
        puts opts
        exit
   end
end

optparse.parse!

if not options[:fastq1] or not options[:fastq2] or not options[:prefix] or not File.exist?(options[:fastq1]) or not File.exist?(options[:fastq2])
    puts optparse.help
    exit
end
out1_str = options[:prefix]+"_1.fastq"
out2_str = options[:prefix]+"_2.fastq"
out_single_str = options[:prefix]+"_singleton.fastq"
if File.exist?(out1_str) or File.exist?(out2_str) or File.exist?(out_single_str)
  puts "Output files already exist, delete them manually or specify a nonexistent file."
  puts optparse.help
  exit
end

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

r1_sum = 0
r2_sum = 0
common_sum = 0
single_sum = 0
$stderr.puts "Building hash table..."
read1_hash = Hash.new
read2_hash = Hash.new
r2 = FastqRead.parseRead(fastq2)
until r2.nil?
  read2_hash[r2.get_key] = r2
  r2_sum+=1
  r2 = FastqRead.parseRead(fastq2)
end
$stderr.puts "Done."

$stderr.puts "Reading fastq1."
output1 = File.new(out1_str, "w")
output2 = File.new(out2_str, "w")
output_single = File.new(out_single_str, "w")
r1 = FastqRead.parseRead(fastq1)
until r1.nil?
  read1_hash[r1.get_key] = r1
  r1_sum += 1
  r2 = read2_hash[r1.get_key]
  if not r2.nil?
    common_sum += 1
    output1.puts(r1.to_s)
    output2.puts(r2.to_s)
  else
    single_sum += 1
    output_single.puts(r1.to_s)
  end
  r1 = FastqRead.parseRead(fastq1)
end
$stderr.puts "Done."

$stderr.puts "Scanning fastq2 ids."
read2_hash.each do |k, v|
    r = read1_hash[k]
    if r.nil?
        single_sum += 1
        output_single.puts(v.to_s)
    end        
end
$stderr.puts "Done."

output1.close
output2.close
output_single.close

$stderr.puts "#all read1: #{r1_sum}\n#all read2: #{r2_sum}\n#matching: #{common_sum}\n#single: #{single_sum}"





