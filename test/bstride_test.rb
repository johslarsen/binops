#!/usr/bin/env ruby
# encoding "UTF-8"
require_relative 'test_helper'
require_relative 'common'

class BstrideTest < Minitest::Test
  def test_width_and_that_epipe_is_handled_correctly
    IotaMatrix.new(8, 16).as_tempfile do |f|
      # NOTE: the diagonals (i.e. misaligned by one)
      assert_equal <<EOF, `#{BIN}/bstride -f..3 -w15 #{f.path} | head -c 16 | #{BIN}/xd -Anone -w4`
 00 01 02 03
 0f 10 11 12
 1e 1f 20 21
 2d 2e 2f 30
EOF
    end
  end

  def test_fields_utf8_and_literal
    IotaMatrix.new(4, 16).as_tempfile do |f|
      # NOTE: the diagonals (i.e. misaligned by one)
      assert_equal <<EOF, `#{BIN}/bstride -f..1,0xa..11 -p"0x1234:l>" -p"0x5678:s_" -tæøå -f-2.. -p0x13,0x37 #{f.path} | #{BIN}/xd -Anone -w20`
 00 01 0a 0b 00 00 12 34 78 56 c3 a6 c3 b8 c3 a5 0e 0f 13 37
 10 11 1a 1b 00 00 12 34 78 56 c3 a6 c3 b8 c3 a5 1e 1f 13 37
 20 21 2a 2b 00 00 12 34 78 56 c3 a6 c3 b8 c3 a5 2e 2f 13 37
 30 31 3a 3b 00 00 12 34 78 56 c3 a6 c3 b8 c3 a5 3e 3f 13 37
EOF
    end
  end

  def test_unpack
    IotaMatrix.new(4, 16).as_tempfile do |f|
      assert_equal <<~EOF.chomp, `#{BIN}/bstride -tHex: -u2..4,0xe "-u8..11:s>*? 0x%04x" -t$'\\n' #{f.path}`
        Hex: 02 03 04 0e 0x0809 0x0a0b
        Hex: 12 13 14 1e 0x1819 0x1a1b
        Hex: 22 23 24 2e 0x2829 0x2a2b
        Hex: 32 33 34 3e 0x3839 0x3a3b
        Hex:
      EOF
    end
  end

  def test_skip_and_partial_end_of_record
    IotaMatrix.new(4, 16).as_tempfile do |f|
      # NOTE: skip does not have to be a multiple of the width
      assert_equal <<EOF, `#{BIN}/bstride -f..-2 -s7 #{f.path} | #{BIN}/xd -Anone -w15`
 07 08 09 0a 0b 0c 0d 0e 0f 10 11 12 13 14 15
 17 18 19 1a 1b 1c 1d 1e 1f 20 21 22 23 24 25
 27 28 29 2a 2b 2c 2d 2e 2f 30 31 32 33 34 35
 37 38 39 3a 3b 3c 3d 3e 3f
EOF
    end
  end

  def test_multiple_files_filter_and_count
    IotaMatrix.new(4, 16).as_tempfile do |f|
      Tempfile.create do |rev|
        rev.write(f.read.reverse)
        rev.flush
        # NOTE: -c2, means upto 2 records from each file
        assert_equal <<EOF, `#{BIN}/bstride -f.. -s8 -g"0>0x10" -c2 #{f.path} #{rev.path} | #{BIN}/xd -Anone `
 18 19 1a 1b 1c 1d 1e 1f 20 21 22 23 24 25 26 27
 28 29 2a 2b 2c 2d 2e 2f 30 31 32 33 34 35 36 37
 37 36 35 34 33 32 31 30 2f 2e 2d 2c 2b 2a 29 28
 27 26 25 24 23 22 21 20 1f 1e 1d 1c 1b 1a 19 18
EOF
      end
    end
  end

  def test_no_input
    assert_equal <<EOF, `#{BIN}/bstride -p 0..7,0xf7..0xf0 -p 0,0xff^8 -c2 | #{BIN}/xd -Anone`
 00 01 02 03 04 05 06 07 f7 f6 f5 f4 f3 f2 f1 f0
 00 ff 00 ff 00 ff 00 ff 00 ff 00 ff 00 ff 00 ff
 00 01 02 03 04 05 06 07 f7 f6 f5 f4 f3 f2 f1 f0
 00 ff 00 ff 00 ff 00 ff 00 ff 00 ff 00 ff 00 ff
EOF
  end

  def test_stdin
    assert_equal <<~EOF, pipe("#{BIN}/bstride", "-w#{16 * 3}", "-f0..2,7..9,11..", stdin: IotaMatrix.new(4, 16).to_ascii)
      00 2 0 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f
      10 2 1 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f
      20 2 2 24 25 26 27 28 29 2a 2b 2c 2d 2e 2f
      30 2 3 34 35 36 37 38 39 3a 3b 3c 3d 3e 3f
    EOF
  end

  def test_stdin_and_other_files
    Tempfile.create do |rev|
      input = IotaMatrix.new(4, 16).to_ascii
      rev.write "#{input.chomp.reverse}\n"
      rev.flush
      # NOTE: only reverse, need '-' parameter to read stdin and other files
      assert_equal <<~EOF, pipe("#{BIN}/bstride", "-w#{16 * 3}", "-f0..-1", rev.path, stdin: input)
        f3 e3 d3 c3 b3 a3 93 83 73 63 53 43 33 23 13 03
        f2 e2 d2 c2 b2 a2 92 82 72 62 52 42 32 22 12 02
        f1 e1 d1 c1 b1 a1 91 81 71 61 51 41 31 21 11 01
        f0 e0 d0 c0 b0 a0 90 80 70 60 50 40 30 20 10 00
      EOF

      assert_equal <<~EOF, pipe("#{BIN}/bstride", "-w#{16 * 3}", "-f..", rev.path, '-', stdin: input)
        f3 e3 d3 c3 b3 a3 93 83 73 63 53 43 33 23 13 03
        f2 e2 d2 c2 b2 a2 92 82 72 62 52 42 32 22 12 02
        f1 e1 d1 c1 b1 a1 91 81 71 61 51 41 31 21 11 01
        f0 e0 d0 c0 b0 a0 90 80 70 60 50 40 30 20 10 00
        00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f
        10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f
        20 21 22 23 24 25 26 27 28 29 2a 2b 2c 2d 2e 2f
        30 31 32 33 34 35 36 37 38 39 3a 3b 3c 3d 3e 3f
      EOF
    end
  end

  INCREMENTAL_VLEN = [2, 0x32, 3, 0x33, 0, 4, 0x34, 0, 0, 5, 0x35, 0, 0, 0].pack("C*")
  def test_simple_vlen_record
    assert_equal <<EOF, pipe("#{BIN}/bstride", "-l0:C", "-u..", "-t\n", stdin: INCREMENTAL_VLEN)
 02 32
 03 33 00
 04 34 00 00
 05 35 00 00 00
EOF
  end

  def test_complicated_vlen_record
    a_record = proc do |payload|
      "HEADER#{[payload.length].pack('S>')}#{payload}FOOTER"
    end
    input = "SKIP THIS PART  "
    nskip = input.length
    input << a_record.call([0x1337].pack("S>"))
    assert_equal "SKIP THIS PART  HEADER\x00\x02\x13\x37FOOTER", input
    input << a_record.call(([0x13] * 0x37).pack("C*"))
    input << a_record.call(([0x12] * 0x3456).pack("C*"))
    input << a_record.call(([0x34] * 0x0ff0).pack("C*"))
    input << a_record.call(([0xff] * 0xffff).pack("C*"))
    input << a_record.call([0xdeadbeef].pack("L>"))
    input << a_record.call(([0x13] * 0xff).pack("C*"))[0..20] # partial record
    output = pipe("#{BIN}/bstride", "-s#{nskip}", "-l6..7+14", "-u8..-7", "-t\n", stdin: input)
    assert_equal <<~EOF, pipe("#{BIN}/uniq_cols.gawk", stdin: output)
      13 37
      13*37
      12*3456
      34*ff0
      ff*ffff
      de ad be ef
      13*0d
    EOF
  end

  DEVNULL = { out: '/dev/null', err: '/dev/null', in: '/dev/null' }
  def test_errors
    refute system "#{BIN}/bstride", '-w-1', DEVNULL # NonNegative, same for -s
    refute system "#{BIN}/bstride", '-ff', DEVNULL # Not a number
    refute system "#{BIN}/bstride", '-f0-3', DEVNULL # Not a range
    refute system "#{BIN}/bstride", '-f0..1..3', DEVNULL # Not a range
    refute system "#{BIN}/bstride", '-pfoo', DEVNULL # Not a Binops.generate literal
  end
end
