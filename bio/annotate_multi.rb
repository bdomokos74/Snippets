require 'bio'
require 'set'

aln_file = "/data/projects/current/trep.aln"

report = Bio::ClustalW::Report.new(File.read(aln_file))
msa = report.alignment
ml = report.match_line
keys = msa.keys

def gettype(index, msa, keys)
  s = Set.new()
  s.add(msa[keys[0]][index])
  s.add(msa[keys[1]][index])
  s.add(msa[keys[2]][index])
  s.add(msa[keys[3]][index])
  s.add(msa[keys[4]][index])
  if s.length==1
    return "*"
  end
  if s.length==2
    if s.member?("-")
      return "g"
    else
      return "v"
    end
  end
  return "m"
end

if ARGV.length == 2
  loc = ARGV[0].to_i
  len = ARGV[1].to_i
  $stderr.puts "#{ml[loc,len]}\n"
  for k in keys
    $stderr.puts "#{msa[k][loc,len]}\n"
  end
  exit
end
inregion = false
current = []
pos = 0
$stderr.puts ml.length
for i in 0..(ml.length-1)
  if not inregion
    #$stderr.puts "inregion #{i}, #{ml[i]}\n"
    if ml[i]==' '
      inregion = true
      pos = i
      current.push(gettype(i, msa, keys))
    end
  else
    #$stderr.puts "NOT inregion #{i}, #{ml[i]}\n"
    if ml[i]=='*'
      str = current.join("")
      puts "#{pos},#{current.length},#{str}\n"
      inregion = false
      current = []
    else
      current.push(gettype(i, msa, keys))
    end
  end
end

if not current.empty?
  str = current.join("")
  puts "#{pos},#{current.length},#{str}\n"
end
