require 'test_helper'

# Run this on command line as: ruby -Itest test/unit/event_test.rb
class EventTest < ActiveSupport::TestCase
  def test_parse_date()
    assert_equal("15 08 1947",
                 Event.parse_date("15 Aug 1947").strftime("%d %m %Y"))
    assert_equal("15 08 1947",
                 Event.parse_date("15 August 1947").strftime("%d %m %Y"))
    assert_equal("15 08 1947",
                 Event.parse_date("Aug 15 1947").strftime("%d %m %Y"))
    assert_equal("15 08 1947",
                 Event.parse_date("August 15 1947").strftime("%d %m %Y"))

    # Check if lower case works
    assert_equal("15 08 1947",
                 Event.parse_date("august 15 1947").strftime("%d %m %Y"))
    assert_equal("15 08 1947",
                 Event.parse_date("15 aug 1947").strftime("%d %m %Y"))

    assert_equal("01 03 1755",
                 Event.parse_date("Mar 1755").strftime("%d %m %Y"))
    assert_equal("01 03 1755",
                 Event.parse_date("March 1755").strftime("%d %m %Y"))

    # AD
    assert_equal("01 01 1005",
                 Event.parse_date("1005 AD").strftime("%d %m %Y"))
    assert_equal("01 01 0650",
                 Event.parse_date("650 AD").strftime("%d %m %Y"))
    assert_equal("01 01 0048",
                 Event.parse_date("48 AD").strftime("%d %m %Y"))
    assert_equal("01 01 0009",
                 Event.parse_date("9 AD").strftime("%d %m %Y"))

    # BC
    assert_equal("01 01 -2500",
                 Event.parse_date("2500 BC").strftime("%d %m %Y"))
    assert_equal("01 01 -0320",
                 Event.parse_date("320 bce").strftime("%d %m %Y"))
    assert_equal("01 01 -0045",
                 Event.parse_date("45 BC").strftime("%d %m %Y"))
    assert_equal("01 01 -0005",
                 Event.parse_date("5 BCE").strftime("%d %m %Y"))

    # Just numbers - treated as years
    assert_equal("01 01 1947",
                 Event.parse_date("1947").strftime("%d %m %Y"))
    assert_equal("01 01 0650",
                 Event.parse_date("650").strftime("%d %m %Y"))
    assert_equal("01 01 0042",
                 Event.parse_date("42").strftime("%d %m %Y"))
  end

  def test_parse_date_negative()
    assert_raise ArgumentError do
      Event.parse_date("1947 August")
    end
    assert_raise ArgumentError do
      Event.parse_date("Augu 1947")
    end
    assert_raise ArgumentError do
      Event.parse_date("15 SSS 1947")
    end
    assert_raise ArgumentError do
      Event.parse_date("WWW 1947")
    end
  end

end
