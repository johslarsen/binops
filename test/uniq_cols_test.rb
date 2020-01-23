#!/usr/bin/env ruby
require_relative 'test_helper'
require_relative 'common'

class UniqColsTest < Minitest::Test

  INPUT = <<EOF
01
01 01
01 02
01 01 01
01 01 02
01 02 02
01 02 01
01 02    03
01 02 02 01
01 0#{(["2"]*10).join(" ")} 0#{(["3"]*20).join(" ")} 0#{(["2"]*10).join(" ")} 01
EOF

  def test_from_stdin
    assert_equal <<EOF, pipe("#{BIN}/uniq_cols.gawk", stdin: INPUT)
01
01*02
01 02
01*03
01*02 02
01 02*02
01 02 01
01 02 03
01 02*02 01
01 02*0a 03*14 02*0a 01
EOF
  end

  def test_npad
    assert_equal <<EOF, pipe("#{BIN}/uniq_cols.gawk", "-vnpad=0", stdin: INPUT)
01
01*2
01 02
01*3
01*2 02
01 02*2
01 02 01
01 02 03
01 02*2 01
01 02*a 03*14 02*a 01
EOF
    assert_equal <<EOF, pipe("#{BIN}/uniq_cols.gawk", "-vnpad=3", stdin: INPUT)
01
01*002
01 02
01*003
01*002 02
01 02*002
01 02 01
01 02 03
01 02*002 01
01 02*00a 03*014 02*00a 01
EOF
  end

  def test_ifs_ofs
    csv = <<EOF
1,2 , 2,2, 2 ,3,3,4
EOF
    # NOTE: awk ignores surrounding white space when comparing fields
    assert_equal <<EOF, pipe("#{BIN}/uniq_cols.gawk", "-F,", "-vOFS=|", stdin: csv)
1|2 *04|3*02|4
EOF
  end
end
