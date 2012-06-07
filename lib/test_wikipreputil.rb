# encoding: UTF-8
require 'test/unit'
require './wikipreputil.rb'

class TestWikiprepUtil < Test::Unit::TestCase
  def setup
  end

  def test_make_path_prefix
    wu = WikiprepUtil.instance
    
    s = "23456"
    (a, b) = wu.make_path_prefix(s)
    assert_equal("23", a)
    assert_equal("45", b)

    s = "9876"
    (a, b) = wu.make_path_prefix(s)
    assert_equal("98", a)
    assert_equal("76", b)
    
    s = "674"
    (a, b) = wu.make_path_prefix(s)
    assert_equal("06", a)
    assert_equal("74", b)

    s = "53"
    (a, b) = wu.make_path_prefix(s)
    assert_equal("00", a)
    assert_equal("53", b)

    s = "9"
    (a, b) = wu.make_path_prefix(s)
    assert_equal("00", a)
    assert_equal("09", b)
  end

end
