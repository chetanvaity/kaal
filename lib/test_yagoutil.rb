# encoding: UTF-8
require 'test/unit'
require './util.rb'
require './yagoutil.rb'

class TestYagoUtil < Test::Unit::TestCase
  def setup
  end
  
  def test_get_date
    yu = YagoUtil.instance
    
    s1 = '148#-##-##'
    d1 = yu.get_date(s1)
    assert_equal(1480, d1.year)
    assert_equal(1, d1.month)
    assert_equal(1, d1.day)

    s2 = '0##-##-##'
    d2 = yu.get_date(s2)
    assert_equal(0, d2.year)
    assert_equal(1, d2.month)
    assert_equal(1, d2.day)

    s3 = '1861-##-##'
    d3 = yu.get_date(s3)
    assert_equal(1861, d3.year)
    assert_equal(1, d3.month)
    assert_equal(1, d3.day)
    
    s4 = '1960-11-##'
    d4 = yu.get_date(s4)
    assert_equal(1960, d4.year)
    assert_equal(11, d4.month)
    assert_equal(1, d4.day)
  end

  def test_get_title
    yu = YagoUtil.instance
    t1 = yu.get_title('Battle_of_Surat')
    assert_equal('Battle of Surat', t1)

    t2 = yu.get_title('Andr\u00e9_the_Giant')
    assert_equal('Andr\u00e9 the Giant', t2)
  end
end
