#!/usr/bin/env ruby
require_relative 'test_helper'
require 'record_view'
require_relative 'common'

class RecordViewTest < Minitest::Test
  def test_indexing
    with_foobar_tempfile do |f|
      r = RecordView.new f, 2, 3
      assert_equal "O", r[0..0]
      assert_equal "B", r[1..1]
      assert_equal "A", r[2..2]
      assert_equal "A", r[-1..-1]
      assert_equal "OB", r[0..1]
      assert_equal "OB", r[0...2]
      assert_equal "OB", r[0..-2]
      assert_equal "OB", r[-3..-2]
      assert_equal "BA", r[-2..-1]
      assert_equal "BA", r[1..2]
      assert_equal "BA", r[1..10]
      assert_equal "BA", r[1..-1]
      assert_equal "OBA", r[0..-1]
      assert_equal "OBA", r[0..2]
      assert_equal "OBA", r[-3..-1]
      assert_equal "OBA", r[0...3]
      assert_equal "OBA", r[0...10]

      assert_equal "", r[1..0]
      assert_equal "", r[3..3]
      assert_equal "", r[3..10]
    end
  end

  def test_replace
    with_foobar_tempfile do |f|
      r = RecordView.new f, 2, 2
      assert_equal "OB", r[0..-1]

      r.replace(0,3)
      assert_equal "FOO", r[0..-1]
    end
  end

  UR = RecordView::UnpackedRange
  def test_scripted_write
    with_foobar_tempfile do |f|
      r = RecordView.new f, 1, 4
      io = StringIO.new

      r.scripted_write io, ["foo ", 1..2, UR.new(2..-1), UR.new(2..-1, "S<"),
                            UR.new(0..-1, "S<*", ",%x")]
      assert_equal "foo OB 42 41 4142,4f4f,4142", io.string
    end
  end

  private

  def with_foobar_tempfile
    Tempfile.create do |f|
      f.write("FOOBAR")
      yield f
    end
  end
end
