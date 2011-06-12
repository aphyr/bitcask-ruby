class Bitcask::DataFile
  # A single Bitcask data file.
  #
  # This is most definitely not threadsafe, but it's so cheap you might as well
  # make lots of copies.

  Entry = Struct.new :tstamp, :key, :value

  include Enumerable

  def initialize(filename)
    @file = File.open(filename)
  end

  # Reads [key, value] from a particular offset.
  # Also advances the cursor.
  def [](offset, size = nil)
    seek offset
    read size
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

  def hint_file
    @hint_file ||= begin
      path = @file.path.sub(/\.data$/, '.hint')
      if File.exists? path
        h = Bitcask::HintFile.new path
        h.data_file = self
        h
      end
    end
  end

  def pos
    @file.pos
  end
  alias tell pos

  # Returns a single Entry read from the current offset, and advances to the
  # next.
  #
  # Can raise Bitcask::ChecksumError
  def read(size = nil)
    if size
      f = StringIO.new @file.read(size)
    else
      f = @file
    end

    # Parse header
    header = f.read(14) or return
    crc, tstamp, ksz, value_sz = header.unpack "NNnN"
    
    # Read data
    key = f.read ksz
    value = f.read value_sz

    # CRC check
    raise Bitcask::ChecksumError unless crc == Zlib.crc32(header[4..-1] + key + value)

    Entry.new tstamp, key, value
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
