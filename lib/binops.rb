#!/usr/bin/env ruby

# Public: Module with common functionality for the project.
module Binops

  # Public: Parse Ranges from e.g. "0x42", "3", "1..3", "0..-1", "3..0xf".
  #
  # string - String to parse.
  #
  # Returns Range.
  # Raises ArgumentError if String does not look like a range.
  def self.parse_range(string)
    case string
    when /^(-?(0[xX])?\h+)$/
      from = Integer($~[1])
      from..from
    when /^(-?(0[xX])?\h+)?\.\.(-?(0[xX])?\h+)?$/
      from = Integer($~[1] || 0)
      to = Integer($~[3] || -1)
      from..to
    else
      raise ArgumentError, "Not a range #{string.inspect}"
    end
  end

  # Public: Same as Binops.parse_range, but
  # Raises ArgumentError for e.g. "-1", "-1..0", "2..1", "1...1".
  def self.parse_postive_increasing_range(string)
    range = parse_range(string)
    raise ArgumentError, "#{string.inspect} is not increasing" unless range.min
    raise ArgumentError, "#{string.inspect} is not positive" if range.min < 0
    range
  end
end
