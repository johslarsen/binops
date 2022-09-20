#!/usr/bin/env ruby
require_relative 'test_helper'
require 'binops'

class BinopsTest < Minitest::Test
  def test_parse_range
    assert_equal 1..1, Binops.parse_range("1")
    assert_equal 1..1, Binops.parse_range("1")
    assert_equal 1..3, Binops.parse_range("1..3")
    assert_equal(-3..-1, Binops.parse_range("-3..-1"))
    assert_equal 0..-1, Binops.parse_range("0..-1")
    assert_equal(-1..1, Binops.parse_range("-1..1"))
    assert_equal 2..1, Binops.parse_range("2..1")

    assert_equal(-0xa..-0xa, Binops.parse_range("-0xA"))
    assert_equal 0xa..0xf, Binops.parse_range("0xa..0xf")
    assert_equal(-0xf..10, Binops.parse_range("-0xf..10"))

    assert_raises(ArgumentError) { Binops.parse_range("foo") }
    assert_raises(ArgumentError) { Binops.parse_range("1...2") }
    assert_raises(ArgumentError) { Binops.parse_range("1..2..3") }
  end

  def test_parse_postive_increasing_range
    assert_equal 0xa..0xa, Binops.parse_postive_increasing_range("0xa")
    assert_equal 1..3, Binops.parse_postive_increasing_range("1..3")

    assert_raises(ArgumentError) { Binops.parse_postive_increasing_range("-1") }
    assert_raises(ArgumentError) { Binops.parse_postive_increasing_range("-1..0") }
    assert_raises(ArgumentError) { Binops.parse_postive_increasing_range("2..1") }
    assert_raises(ArgumentError) { Binops.parse_postive_increasing_range("1...1") }
  end

  def test_generate
    assert_equal [1].pack("C*"), Binops.generate("1")
    assert_equal ([9, 0xa, 0xB] * 2).pack("S*"), Binops.generate("9..0xB:S*^2")
    assert_equal ([1, 6, 5, 4, 0xf] * 3).pack("C*"), Binops.generate("1,6..4,0xf^3")
  end
end
