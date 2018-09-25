#!/usr/bin/env ruby
require 'tempfile'

BIN = File.join File.dirname(__FILE__), '..', 'bin/'

# Public: Run a command and get its output.
#
# *cmd - Strings with name of executable and the command arguments.
# stdin - A String to write as the commands stdin.
#
# Returns String with stdout and stderr from the command.
def pipe(*cmd, stdin: nil)
  IO.popen(cmd, "r+", err: [:child, :out]) do |io|
    io.write stdin if stdin
    io.close_write
    io.read
  end
end

class IotaMatrix
  attr_reader :rows
  def initialize(nrow, ncol)
    @rows = (0...nrow).map do |row|
      (0...ncol).map{|col| (row<<4) + col}
    end
  end

  def to_ascii
    @rows.map{|r| r.map{|c|"%02x"%[c]}.join(" ")}.join("\n") << "\n"
  end

  def as_tempfile
    Tempfile.create do |f|
      @rows.each do |row|
        f.write row.pack("c*")
      end
      f.rewind
      f.flush
      yield f
    end
  end
end
