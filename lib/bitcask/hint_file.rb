class Bitcask::HintFile
  # A single Bitcask hint file.
  #
  # This is most definitely not threadsafe, but it's so cheap you might as well
  # make lots of copies.

  Entry = Struct.new :tstamp, :value_sz, :value_pos, :key

  include Enumerable

  attr_accessor :data_file
  def initialize(filename)
    @file = File.open(filename)
  end

  # Reads [key, value] from a particular offset.
  # Also advances the cursor.
  def [](offset)
    seek offset
    read
  end

  def close
    @file.close
  end

  # Iterates over every entry in this file, yielding an Entry.
  # Options:
  #  :rewind (true) - Rewind the file to the beginning, instead of starting
  #                   right here.
  #  :raise_checksum (false) - Raise Bitcask::ChecksumError on crc failure, 
  #                   instead of silently continuing.
  def each(opts = {})
    options = {
      :rewind => true,
      :raise_checksum => false
    }.merge opts

    rewind if options[:rewind]

    loop do
      o = read
      if o
        yield o
      else
        return self
      end
    end
  end

  def pos
    @file.pos
  end
  alias tell pos

  # Returns [timestamp, key, value_pos, value_size] read from the current
  # offset, and advances to the next.
  #
  # Can raise Bitcask::ChecksumError
  def read
    # Parse header
    header = @file.read(18) or return
    tstamp, ksz, value_sz, value_pos1, value_pos2 = header.unpack "NnNNN"

    # value_pos is an 8 byte big-endian number...
    # For reference, reverse is [value_pos >> 32, value & 0xFFFFFFFF].pack("NN")
    value_pos = (value_pos1 << 32) | value_pos2

    # Read key
    key = @file.read ksz

    Entry.new tstamp, value_sz, value_pos, key
  end

  # Rewinds the file.
  def rewind
    @file.rewind
  end

  # Seek to a given offset.
  def seek(offset)
    @file.seek offset
  end
end
