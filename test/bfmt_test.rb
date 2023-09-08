#!/usr/bin/env ruby
require 'minitest/autorun'
require_relative 'common'

class BfmtTest < Minitest::Test
  def test_examples
    Dir.mktmpdir do |tmp|
      File.write("#{tmp}/foo", "foo")
      File.write("#{tmp}/bar", "bar")
      File.write("#{tmp}/foobar", "foobar")

      assert_equal("FOObarBAZ", pipe("#{BIN}/bfmt", "FOO{0}BAZ", stdin: "bar"))
      assert_equal("foobar", pipe("#{BIN}/bfmt", "{}{}", "#{tmp}/foo", "#{tmp}/bar"))
      assert_equal("fo ar", pipe("#{BIN}/bfmt", "{1:0:2} {1:2}", "#{tmp}/foobar"))
      assert_equal("fo ba", pipe("#{BIN}/bfmt", "{1:0:2} {1:@3:@5}", "#{tmp}/foobar"))
    end
  end
end
