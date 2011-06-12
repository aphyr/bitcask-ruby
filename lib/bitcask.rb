class Bitcask
  require 'zlib'

  $LOAD_PATH << File.expand_path(File.dirname(__FILE__))

  require 'bitcask/hint_file'
  require 'bitcask/data_file'
  require 'bitcask/keydir'
  require 'bitcask/errors'
  require 'bitcask/version'

  include Enumerable

  TOMBSTONE = "bitcask_tombstone"

  # Opens a bitcask backed by the given directory.
  attr_accessor :keydir
  attr_reader :dir
  def initialize(dir)
    @dir = dir
    @keydir = Bitcask::Keydir.new
  end

  # Uses the keydir to get an object from the bitcask. Returns a
  # Bitcask::DataFile::Entry.
  def [](key)
    index = @keydir[key]
    @keydir.data_files[index.file_id][index.value_pos, index.value_sz]
  end

  # Returns a list of all data filenames in this bitcask, sorted from oldest
  # to newest.
  def data_file_names
    Dir.glob(File.join(@dir, '*.data')).sort! do |a, b|
      a.to_i <=> b.to_i
    end
  end

  # Returns a list of Bitcask::DataFiles in chronological order.
  def data_files
    data_file_names.map! do |filename|
      Bitcask::DataFile.new filename
    end
  end

  # Iterates over all keys in keydir. Yields Bitcask::DataFile::Entries.
  def each
    @keydir.each do |key, index|
      yield @keydir.data_files[index.file_id][index.value_pos, index.value_sz]
    end
  end

  # Keydir keys.
  def keys
    keydir.keys
  end

  # Populate the keydir.
  def load
    data_files.each do |d|
      if h = d.hint_file
        load_hint_file h
      else
        load_data_file d
      end
    end
  end

  # Load a DataFile into the keydir.
  def load_data_file(data_file)
    # Determine data_file index.
    @keydir.data_files |= [data_file]
    file_id = @keydir.data_files.index data_file
   
    pos = 0
    data_file.each do |entry|
      # Check for existing newer entry in keydir
      if (cur = @keydir[entry.key]).nil? or entry.tstamp >= cur.tstamp
        @keydir[entry.key] = Keydir::Entry.new(
          file_id,
          data_file.pos - pos,
          pos,
          entry.tstamp
        )
      end

      pos = data_file.pos
    end
  end
  
  # Load a HintFile into the keydir.
  def load_hint_file(hint_file)
    # Determine data_file index.
    @keydir.data_files |= [hint_file.data_file]
    file_id = @keydir.data_files.index hint_file.data_file

    hint_file.each do |entry|
      # Check for existing newer entry in keydir
      if (cur = @keydir[entry.key]).nil? or entry.tstamp >= cur.tstamp
        @keydir[entry.key] = Keydir::Entry.new(
          file_id,
          entry.value_sz,
          entry.value_pos,
          entry.tstamp
        )
      end
    end
  end

  # Keydir size.
  def size
    @keydir.size
  end
end
