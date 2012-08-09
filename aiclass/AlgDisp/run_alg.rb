require 'rubygems'
require 'launchy'
require 'graphviz'

class SimpleGraph
  attr_reader :nodes, :g
  
  def initialize()
    @nodes = []
    @g = Hash.new
  end

  def get_neighbours(n)
    node = @g[n]
    node[:neighbours]
  end

  def debug_graph()
    puts "Graph:\n"
    @nodes.each do |n|
      debug_node(n)
    end
  end

  def debug_node(n)
    puts("[#{n}]")
    weights = @g[n][:weights]
    @g[n][:neighbours].each_with_index do |neighbour, i|
      puts "\t#{neighbour} ; #{weights[i]}\n"
    end
  end

  def plot_graph(step, frontier, expanded, next_node, start, goal)
    puts "step_#{step} : #{next_node}"
    File.open("graph.tmp", "w") do |tmp_graph|
      plot_graph_header(tmp_graph);
      plot_graph_nodes(tmp_graph, frontier, expanded, next_node, start, goal)
      plot_graph_edges(tmp_graph, frontier, expanded, next_node, goal)
      plot_graph_footer(tmp_graph );
    end
    `neato -Tpng graph.tmp > output/graph_#{step}.png`
  end
  
  def plot_graph_header(outfile)
    outfile.puts "graph G {\n\toverlap=\"false\"\n\tratio = 0.66;\n\compress = true;\n\theadlabel = true;\n";
  end
  def plot_graph_footer(outfile)
    outfile.puts "}\n";
  end
  def plot_graph_nodes(outfile, frontier, expanded, next_node, start, goal)
    @nodes.each do |n|
      shape = "circle"
      shape = "doublecircle" if n==goal;
      styles = []
      styles << "filled" if expanded.include?(n)
      styles << "bold" if n==start
      styles << "dashed" unless frontier.include?(n) || expanded.include?(n) || goal == n
      fillcolor = "/blues3/2" if n == next_node
      outfile.puts("\t#{n} [style = \"#{styles.join(',')}\", shape = #{shape}, \
        fillcolor=\"#{fillcolor}\", fixedsize = true, label=\"\", xlabel = \"#{n}\"];")
    end
  end
  def plot_graph_edges(outfile, frontier, expanded, next_node, goal)
    @plotted_edge = []
    @nodes.each do |n|
      weights = @g[n][:weights]
      @g[n][:neighbours].each_with_index do |neighbour, i|
        next if @plotted_edge.member?("#{neighbour}--#{n}")
        styles = []
        if (!( (expanded.include?(n) || frontier.include?(n)) &&
          (expanded.include?(neighbour) || frontier.include?(neighbour))) )
          styles << "dashed"
        end
        outfile.puts("\t#{n} -- #{neighbour} [label=\"#{weights[i]}\", style=\"#{styles.join(',')}\"];\n")
        @plotted_edge << "#{neighbour}--#{n}"
        @plotted_edge << "#{n}--#{neighbour}"
      end
    end
  end

  def self.read_graph(filename)
     gv = GraphViz.parse(filename)
     new_graph = SimpleGraph.new
     
     i = 0
     gv.each_edge do |e|
       n1 = e.node_one().to_s
       n2 = e.node_two().to_s
       w = e["label"].to_s
       w.gsub!('"', '')
       w = w.to_f
       if !new_graph.g.member?(n1)
         new_graph.nodes << n1
         adj = [n2]
         new_graph.g[n1] = { :name => n1, :neighbours => adj, :weights => [w]}
       end

       if !new_graph.g.member?(n2)
         new_graph.nodes << n2
         adj = [n1]
         new_graph.g[n2] = { :name => n2, :neighbours => adj, :weights => [w]}
       end

       # TODO refactor
       node = new_graph.g[n1]
       if !node[:neighbours].include?(n2) 
         node[:neighbours] << n2
         node[:weights] << w
       end
       node = new_graph.g[n2]
       if !node[:neighbours].include?(n1) 
         node[:neighbours] << n1
         node[:weights] << w
       end

       puts "read e[#{i}] : #{n1} -- #{n2} ; #{w}\n"
       i += 1
     end
     new_graph
  end  
end

class SearchAlg
  def search(graph, start, goal)
    @frontier = [start]
    @expanded = []

    step = 1
    while(1) do
      return step if @frontier.empty?
      next_node = choose_next()
      # @frontier.shift
      @expanded << next_node

      puts("step: #{step}, exp:[#{@expanded.join(',')}], front:[#{@frontier.join(',')}]")
      graph.plot_graph(step, @frontier, @expanded, next_node, start, goal)

      if next_node == goal
        return step;
      end

      graph.get_neighbours(next_node).each do |n|
        return step if n == goal
        @frontier.push(n) unless @expanded.member?(n) || @frontier.include?(n)
      end
      step+=1
    end
  end
end

class BreadthFirst < SearchAlg
  def choose_next
      @frontier.shift
  end
end

class DepthFirst < SearchAlg
  def choose_next
      @frontier.pop
  end
end

def generate_html(title, prefix, n)
  html = <<eos
<!DOCTYPE html>
<html>
  <title>#{title} alg steps</title>
  <head>
  <style>
    div.figure {
      border: thin silver solid;
      margin: 0.5em;
      padding: 0.5em;
    }
  </style>
  </head>
  <body>
    <table>
    @alg_steps_html@
    </table>
  </body>
</html>
eos

  img_tag = <<eos
  <tr><td>
  <div class="figure">
  <p><img src="@img_file@" /></img></p>
  <p>Step @step@</p>
  </div>
  </td></tr>
eos
  
  File.open("output/result.html", "w") do |result_file|
    img_tags = []
    n.times do |i|
      img_tags << img_tag.gsub("@img_file@", "#{prefix}_#{i+1}.png").gsub("@step@", "#{i+1}")
    end
    html.gsub!("@alg_steps_html@", img_tags.join("\n"))
    result_file.puts(html);
  end
end

######################

g = SimpleGraph.read_graph("map1.gv")
g.debug_graph()

start = "Arad"
goal = "Bucharest"

alg = BreadthFirst.new
nsteps = alg.search(g, start, goal)

generate_html("Breadth-first search", "graph", nsteps)

Launchy::open("output/result.html")


