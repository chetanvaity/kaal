require 'test_helper'

# Run this on command line as: ruby -Itest test/unit/babel_test.rb
class BabelTest < ActiveSupport::TestCase
  def test_get_normalized_query()
    assert_equal("hello world", Babel.get_normalized_query("hello world"))
    assert_equal("r.d.burman", Babel.get_normalized_query("pancham"))
    assert_equal("india shivaji", Babel.get_normalized_query("india king shivaji"))
    assert_equal("india shivaji", Babel.get_normalized_query("bharat chatrapati shivaji"))
    assert_equal("r.d.burman", Babel.get_normalized_query("pancham"))
    assert_equal("r.d.burman india", Babel.get_normalized_query("pancham bharat"))
  end
end
