class Bitcask::DataFile
  # A single Bitcask data file.
  #
  # This is most definitely not threadsafe, but it's so cheap you might as well
  # make lots of copies.

  def initialize(filename)
    @file = File.open(filename)
  end

  # Reads [key, value] from a particular offset.
  # Also advances the cursor.
  def [](offset)
    seek offset
    read
  end
 
  # Iterates over every entry in this file, yielding the key and value.
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
      begin
        o = read
        if o
          yield o
        else
          return self
        end
      rescue Bitcask::ChecksumError => e
        raise e if options[:raise]
      end
    end
  end

  def pos
    @file.pos
  end
  alias tell pos

  # Returns a single [key, value] pair read from the current offset,
  # and advances to the next.
  #
  # Can raise Bitcask::ChecksumError
  def read
    # Parse header
    header = @file.read(14) or return
    crc, tstamp, ksz, value_sz = header.unpack "NNnN"
    
    # Read data
    key = @file.read ksz
    value = @file.read value_sz

    # CRC check
    raise Bitcask::ChecksumError unless crc == Zlib.crc32(header[4..-1] + key + value)

    [key, value]
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
