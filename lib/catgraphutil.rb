# encoding: UTF-8
require 'fileutils'
require 'singleton'
require 'logger'
require 'rgl/adjacency'
require 'rgl/traversal'
require 'depq'

# Category graph
class CatgraphUtil
  include Singleton
  INFINITY = 1.0/0.0

  def initialize
    @log = Logger.new("/home/chetanv/source/kaal/log/catgraphutil.log",
                      "monthly") 
    @log.level = Logger::INFO
    @log.info "initialize(): -----"
    @dg = RGL::DirectedAdjacencyGraph[]
  end

  # Create a graph from file with vertices and their connections
  #  1: 9 8 7 (1 is connected to 9, 8 and 7)
  #  2: 5 6 4
  def make_graph(fname)
    open(fname).each_line do |line|
      l1 = line.chomp.rstrip.split(/:/)
      next if (l1.nil? or l1.length != 2)
      cat_id = l1[0]
      parent_cat_ids = l1[1].chomp.rstrip.split(/\s/).reject {|e| e.length==0}
      parent_cat_ids.each {|p| @dg.add_edge(cat_id, p)}
    end
  end

  # All the vertices of the cat graph
  def get_vertices()
    return @dg.vertices
  end

  # Find the shortest path from source vertex to any one of the finish vertices
  # Look at http://en.wikipedia.org/wiki/Dijkstra's_algorithm
  def shortest_path(source, finish_list)
    dist = {} # The distance of all vertices from start vertex
    prev = {} # Previous node in the optimal path
    q = Depq.new

    @dg.each_vertex do |v|
      # dist contains the "Depq::Locator" for that value
      dist[v] = (v == source) ? q.insert(v, 0) : q.insert(v, INFINITY)
    end

    while not q.empty?
      u = q.delete_min
      if dist[u].priority == INFINITY
        @log.info("shortest_path(): dist[#{u}] == Infinity")
        break
      end
      if finish_list.include?(u)
        finish_vertex = u
        break
      end
      @dg.adjacent_vertices(u).each do |v|
        alt = dist[u].priority + 1
        if alt < dist[v].priority
          dist[v].update(v, alt)
          prev[v] = u
        end
      end
    end # while

    s = [] # The shortest path from source to finish_vertex
    w = finish_vertex
    while not prev[w].nil?
      s.push(w)
      w = prev[w]
    end

    return s
  end

end
