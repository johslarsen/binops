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

  def test_dev_zero
    assert_equal("\0" * 15, pipe("#{BIN}/bfmt", "{::10}{1:10:5}", "/dev/zero"))
  end

  def test_pipes
    assert_equal("bar", pipe("#{BIN}/bfmt", "{0:3}", stdin: "foobar"))
  end

  def test_fallback
    # splice requires at least one of the file descriptors to be a pipe
    Dir.mktmpdir do |tmp|
      File.write("#{tmp}/foobar", "foobar")
      assert(system("#{BIN}/bfmt", "{:3}", "#{tmp}/foobar", out: "#{tmp}/output"))
      assert_equal("bar", File.read("#{tmp}/output"))
    end
  end
end
