# encoding: UTF-8
require 'test/unit'
require './catgraphutil.rb'

class TestCatgraphUtil < Test::Unit::TestCase
  def setup
    @graph_file = '/home/chetanv/source/kaal/lib/graph.test'
  end
  
  def test_make_graph
    cu = CatgraphUtil.instance
    cu.make_graph(@graph_file)
    assert_equal(6, cu.get_vertices.length)
  end

  def test_shortest_path
    cu = CatgraphUtil.instance
    cu.make_graph(@graph_file)
    assert_equal(3, cu.shortest_path("1", ["6"]).length)
    assert_equal(2, cu.shortest_path("1", ["3", "6"]).length)
    assert_equal(1, cu.shortest_path("1", ["2"]).length)
    assert_equal(0, cu.shortest_path("4", "2").length)
  end
end
