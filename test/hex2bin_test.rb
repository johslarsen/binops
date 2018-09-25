#!/usr/bin/env ruby
require 'minitest/autorun'
require_relative 'common'

class Hex2BinTest < Minitest::Test

  INPUT = <<EOF
0x10 10  a
1-a a*3
EOF

  def test_semantics_from_stdin
    Tempfile.create do |f|
      f.write(pipe("#{BIN}/hex2bin", stdin: INPUT))
      f.flush
      assert_equal <<EOF, `#{BIN}/xd #{f.path}`
000000 10 10 0a 01 02 03 04 05 06 07 08 09 0a 0a 0a 0a
000010
EOF
    end
  end

  def test_iota_from_file
    Tempfile.create do |f|
      m = IotaMatrix.new(4,16)
      f.write(m.to_ascii)
      f.flush
      assert_equal <<EOF, `#{BIN}/hex2bin #{f.path} | #{BIN}/xd`
000000 00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f
000010 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f
000020 20 21 22 23 24 25 26 27 28 29 2a 2b 2c 2d 2e 2f
000030 30 31 32 33 34 35 36 37 38 39 3a 3b 3c 3d 3e 3f
000040
EOF
    end
  end
end
