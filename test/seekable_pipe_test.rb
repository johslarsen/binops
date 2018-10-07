#!/usr/bin/env ruby
require 'minitest/autorun'
require 'seekable_pipe'
require 'socket'
require_relative 'common'

class SeekablePipeTest < Minitest::Test

  INPUT = "FOOBAR"

  def test_as_file_wrapper
    Tempfile.create do |f|
      f.write(INPUT)
      f.flush

      sp = SeekablePipe.new f
      assert_equal "FOO", sp.pread(3, 0)
      assert_equal "BAR", sp.pread(3, 3)
      assert_equal "FOOBAR", sp.pread(6, 0)
      assert_equal "BAR", sp.pread(6, 3)
      assert_nil sp.pread(1, 6)

      sp.clear_buffered # should be a noop when it is a file wrapper
      assert_equal "FOO", sp.pread(3, 0)
    end
  end

  def test_as_sequential_pipe_wrapper
    i, o = UNIXSocket.pair
    i.write(INPUT)
    i.close

    sp = SeekablePipe.new o
    assert_equal "FOO", sp.pread(3, 0)
    assert_equal "BAR", sp.pread(3, 3)
    assert_nil sp.pread(1, 6)
  end

  def test_pipe_wrapper_buffering
    i, o = UNIXSocket.pair
    i.write(INPUT)
    i.close

    sp = SeekablePipe.new o
    assert_equal "FOO", sp.pread(3, 0)
    assert_equal "B", sp.pread(1, 3)
    sp.clear_buffered
    assert_raises(RuntimeError) {sp.pread(1,3)}
    assert_equal "AR", sp.pread(2, 4)
    assert_equal "AR", sp.pread(6, 4)
    assert_nil sp.pread(1, 6)

    sp.clear_buffered
    assert_raises(RuntimeError) {sp.pread(1,5)}
    assert_nil sp.pread(1, 6)
  end

  def test_each_record_fixed_width_and_enumerator
    Tempfile.create do |f|
      f.write INPUT
      records = SeekablePipe.new(f).each_record(2, initial_offset: 1).map do |r|
        r[0..-1].dup
      end
      assert_equal ["OO", "BA", "R"], records
    end
  end

  def test_each_record_variable_length
    Tempfile.create do |f|
      f.write([0x42, 1, 0].pack("C*"))
      f.write([0x42, 2, 0, 0].pack("C*"))
      f.write([0x42, 3, 0, 0, 0].pack("C*"))

      records = []
      SeekablePipe.new(f).each_record(SeekablePipe::Vlen.new(1..1, "C", 2)) do |r|
        records << r[0..-1].dup.unpack("H*").first
      end

      assert_equal ["420100", "42020000", "4203000000"], records
    end
  end

  def test_each_record_filtered
    IotaMatrix.new(16,16).as_tempfile do |f|
      sp = SeekablePipe.new(f)
      filters = [SeekablePipe::Filter.new(0..0, :==, 0x10, 0x10),
                 SeekablePipe::Filter.new(3..4, :>=, 0x8483, nil, "S<")]
      records = sp.each_record_filtered(16, filters:filters, count:7).map do |r|
        r[0..0].ord
      end
      assert_equal [0x10, 0x30, 0x50, 0x70, 0x80, 0x90, 0xa0], records
    end
  end

  def test_stdin_or_each_empty
    files = []
    SeekablePipe.stdin_or_each([]) {|sp| files << extract_file(sp)}
    assert_equal [$stdin], files
  end

  def test_stdin_or_each_with_files_and_dash
    files = []
    Tempfile.create do |a|
      Tempfile.create do |b|
        SeekablePipe.stdin_or_each([a.path, "-", b.path, "-"]) do |sp|
          f = extract_file(sp)
          files << (f == $stdin ? $stdin : f.path)
        end
        assert_equal [a.path, $stdin, b.path, $stdin], files
      end
    end
  end

  private

  def extract_file(seekable_pipe)
    class << seekable_pipe
      attr_reader :file
    end
    seekable_pipe.file
  end

end
