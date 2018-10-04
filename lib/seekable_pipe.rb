#!/usr/bin/env ruby
require_relative 'record_view'

# Public: A file/pipe wrapper that supports a unified pread operation.
class SeekablePipe
  def initialize(file)
    @file = file
    @buffer = String.new encoding: Encoding::ASCII_8BIT # grows as needed
    @pipe_buffer = nil
  end

  # Public: Read data starting at the given SEEK_SET offset. Mimics IO#pread,
  # with the exception that it returns nil instead of raising EOFError if
  # offset is beyond EOF, and that it by default reuses, and returns, an
  # internal buffer for performance reasons.
  #
  # maxlen - Integer read upto this amount of data.
  # offset - Integer offset from start of file to start reading.
  # buffer - Read to this String instead of a reused buffer.
  #
  # Returns a Encoding::ASCII_8BIT String whose length is less than maxlen iff
  # there is no more data available, or nil if the offset is beyond EOF.
  def pread(maxlen, offset, buffer=nil)
    buffer ||= @buffer
    @pipe_buffer ? pipe_read(maxlen, offset, buffer) : @file.pread(maxlen, offset, buffer)
  rescue EOFError
    return nil # act like read
  rescue Errno::ESPIPE
    @pipe_buffer = String.new encoding: Encoding::ASCII_8BIT
    @pb_offset = 0
    retry
  end

  # Public: Process wrapped files/$stdin.
  #
  # fnames - Array of filename Strings, and '-' is interpreted to mean $stdin.
  #
  # Returns fnames.
  # Yields A SeekablePipe wrapping each fname, or $stdin if fnames is empty.
  def self.stdin_or_each(fnames)
    yield self.new($stdin) if fnames.empty?
    fnames.each do |fname|
      if fname == '-'
        yield self.new $stdin
      else
        File.open(fname) {|f| yield self.new(f)}
      end
    end
  end

  # Public: Reads from pipes are internally buffered in order to support
  # seeking backwards. Call this when you know all earlier data is not needed
  # anymore. If this SeekablePipe wraps a file, this is a noop.
  #
  # Returns nothing.
  def clear_buffered
    if @pipe_buffer
      @pb_offset += @pipe_buffer.size
      @pipe_buffer.clear
    end
  end

  private

  def pipe_read(maxlen, offset, buffer)
    raise "Cannot seek earlier than start of pipe buffer" if offset < @pb_offset
    from = offset - @pb_offset
    to = from + maxlen
    nread = to - @pipe_buffer.size
    while nread > 0
      unless @file.read nread, buffer
        return from == @pipe_buffer.size ? nil : @pipe_buffer[from..-1]
      end
      @pipe_buffer << buffer
      nread -= buffer.size
    end
    @pipe_buffer[from...to]
  end
end
