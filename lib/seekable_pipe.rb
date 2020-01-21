#!/usr/bin/env ruby
require_relative 'record_view'
require_relative 'binops'

# Public: A file/pipe wrapper that supports a unified pread operation.
class SeekablePipe
  def initialize(file)
    @file = file
    @buffer = String.new encoding: Encoding::ASCII_8BIT # grows as needed
    @pipe_buffer = nil
    @eof = false
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
    buffer = @pipe_buffer ? pipe_read(maxlen, offset, buffer) : @file.pread(maxlen, offset, buffer)
  rescue EOFError
    return (buffer = nil) # act like read
  rescue Errno::ESPIPE
    @pipe_buffer = String.new encoding: Encoding::ASCII_8BIT
    @pb_offset = 0
    retry
  ensure
    @eof = true if buffer.nil? || buffer.size < maxlen
  end

  # Returns true if io have been pread beyond EOF.
  def eof?
    @eof
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

  Vlen = Struct.new :range, :directive, :nbytes_extra

  # Public: Process the io as consecutive fixed/varible sized records.
  #
  # width - Integer for fixed / Vlen for variable sized records.
  # initial_offset - Integer number of bytes to skip before first record.
  #
  # Returns self or Enumerator if no block is given.
  # Yields a reused RecordView for each record.
  def each_record(width, initial_offset:0)
    unless block_given?
      return to_enum __method__, width, initial_offset: initial_offset
    end

    offset = initial_offset
    record = RecordView.new self, 0
    loop do
      clear_buffered

      length = width
      if length.is_a? Vlen
        break self unless (bytes = pread(width.range.size, offset + width.range.first))
        length = bytes.unpack(width.directive).first + (width.nbytes_extra || 0)
      end

      record.replace offset, length
      yield record

      break self if eof?
      offset += length
    end
  end

  class Filter < Struct.new :range, :comparator, :other, :mask, :directive
    def initialize range, comparator, other, mask=nil, directive="C"
      super
    end
  end

  # Public: SeekablePipe#each_record, but with some filtering functionality.
  #
  # width - See SeekablePipe#each_record.
  # initial_offset - See SeekablePipe#initial_offset
  # filters - Array of filters TODO
  # count - Break after yielding Integer count number of records.
  #
  # Returns self or Enumerator if no block is given.
  # Yields a reused RecordView for each record.
  def each_record_filtered(width, initial_offset:0, filters: [], count:nil)
    unless block_given?
      return to_enum(__method__, width, initial_offset: initial_offset,
                     filters: filters, count: count)
    end

    each_record(width, initial_offset: initial_offset) do |record|
      unless filters.empty?
        next unless filters.any? do |f|
          break false unless (bytes = record[f.range])
          n = bytes.unpack(f.directive).first
          n &= f.mask if f.mask
          n.send f.comparator, f.other
        end
      end
      if count
        break if count <= 0
        count -= 1
      end
      yield record
    end
  end

  # Public: Add options that configure a each_record call.
  #
  # option_parser - The OptionParser to add options to.
  #
  # Returns Array meant as SeekablePipe#each_record arguments.
  def self.each_record_filtered_options(option_parser)
    args = [16]
    kwargs = {initial_offset: 0, count: nil, filters: []}
    o = option_parser

    non_negative = Struct.new :n
    o.accept non_negative do |str|
      raise "Cannot be negative: #{str.inspect}" if (n = Integer(str)) < 0
      n
    end
    o.accept Filter do |range_op_n|
      range_dir_mask,op,n = range_op_n.partition(/\s*([<>]=?|[!=]=)\s*/)
      range_dir,m = range_dir_mask.split("&")
      r,d = range_dir.split(":")
      Filter.new Binops.parse_range(r), op.strip.to_sym, Integer(n), m && Integer(m, 16), d || "C"
    end

    o.separator "Record processing"
    o.on "-w", "--width BYTES", non_negative, "Fixed sized record length. Default: #{args[0]}" do |w|
      args[0] = w
    end
    o.on("-l", "--length N[..M][:DIRECTIVE-=S>][+BYTES]",
         "Variable length record unpacked from N..Mth bytes + BYTES.",
         "Write unpacked ranges of bytes to the output") do |range_directive_bytes|
      range_directive, bytes = range_directive_bytes.split '+'
      rstr, directive = range_directive.split ':'
      range = Binops.parse_postive_increasing_range rstr
      args[0] = Vlen.new(range, directive || "S>", Integer(bytes || 0))
    end

    o.on "-s", "--skip BYTES", non_negative, "Skip the first BYTES" do |offset|
      kwargs[:initial_offset] = offset
    end

    o.separator "Record filtering"
    o.on("-g", '--grep "N[..M][:D-=C][&HEX] OP INT"', Filter,
         'Search for records with unpacked N..Mth bytes (optionally HEX masked)',
         'matching (e.g. ==) INT. If multiple "-g", match any one of them.') do |filter|
      kwargs[:filters] << filter
    end
    o.on "-c", "--count COUNT", non_negative, "Only output COUNT records from each file" do |count|
      kwargs[:count] = count
    end

    [args, kwargs]
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
