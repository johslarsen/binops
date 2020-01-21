#!/usr/bin/env ruby

# Public: Access a view over a preadable_io as an Array-like object.
class RecordView

  # Public: Create a length-sized view at offset into the preadable_io.
  #
  # preadable_io - An IO-like object that supports IO#pread.
  # offset - Start the view at this Integer SEEK_SET offset into the io.
  # length - Integer for what negative indexes will be subtracted from.
  def initialize(preadable_io, offset, length=nil)
    @io = preadable_io
    replace(offset, length)
  end

  # Public: Reset what part of the io the view references.
  #
  # offset - See RecordView#initialize
  # length - See RecordView#initialize
  #
  # Returns nothing
  def replace(offset, length = nil)
    @offset = offset
    @length = length
  end

  # Public: IO#pread bytes relative to the RecordView offset.
  #
  # range - Range with byte offsets relative to start of record. Length must be
  #         set in order to support negative indexes.
  # buffer - Pass this String buffer to pread.
  #
  # Returns String from IO#pread.
  def [](range, buffer=nil)
    to = range.max || range.last # support  a...b (exclusive), and 0..-1 ranges
    from = range.first < 0 ? @length+range.first : range.first
    length = (to < 0 ? @length+to : to) - from + 1
    return "" if length < 0 || @length && from >= @length
    length = @length - from if @length && from + length > @length
    return @io.pread length, @offset + from, buffer
  end

  # Public: A Range associated with how it should be output.
  class UnpackedRange < Struct.new(:range, :directive, :format)
    def initialize(range, directive="C*", format=" %02x")
      super
    end
  end

  # Public: Write a set of operations to the given io.
  #
  # io - IO to write to.
  # *operations - String/Range/UnpackedRange. Will be written in order.
  #
  # Returns io.write or nil if operation needs data beyond EOF.
  def scripted_write(io, operations)
    operations.each do |op|
      case op
      when String
        io.write op
      when Range
        break unless (bytes = self[op])
        io.write bytes
      when UnpackedRange
        break unless (bytes = self[op.range])
        io.write bytes.unpack(op.directive).map{|s| op.format % [s]}.join
      end
    end
  end

  # Public: Add options that configure a scripted_write call.
  #
  # option_parser - The OptionParser to add options to.
  #
  # Returns Array meant as RecordView#scripted_write arguments.
  def self.scripted_write_options(option_parser)
    args = [$stdout, []]
    o = option_parser

    o.separator "Output operations (executed in order specified)"
    o.on "-f", '--fields N,"N..M",...', Array,
        "Copy bytes at indexes / in ranges to output" do |fields|
      args[1].concat(fields.map{|f|Binops.parse_range(f)})
    end
    o.on "-u", '--unpack N,"N..M",...[:DIRECTIVE-=C*][?FORMAT= %02x]',
        "Write unpacked ranges of bytes to the output",
        "See `ri String.unpack` for how to specify DIRECTIVE" do |fields_directive_format|
      fields_directive, format = fields_directive_format.split("?")
      fields, d = fields_directive.split ':'
      args[1].concat(fields.split(',').map do |f|
        UnpackedRange.new(Binops.parse_range(f), d||"C*", format||" %02x")
      end)
    end

    o.on "-t", "--text UTF-8", "Write the UTF-8 literal to the output" do |s|
      args[1] << s
    end
    o.on "-p", "--pack #{Binops::GENERATE_SYNTAX}",
        "Append a generated binary pattern to the output",
        "See `ri Array.pack` for how to specify DIRECTIVE" do |pattern|
      args[1] << Binops.generate(pattern)
    end

    [args, {}]
  end
end
