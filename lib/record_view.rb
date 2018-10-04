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
end
