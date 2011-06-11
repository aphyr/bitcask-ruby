class Bitcask
  require 'zlib'

  $LOAD_PATH << File.expand_path(File.dirname(__FILE__))

  require 'bitcask/hint_file'
  require 'bitcask/data_file'
  require 'bitcask/key_dir'
  require 'bitcask/errors'
  require 'bitcask/version'

  TOMBSTONE = "bitcask_tombstone"

  # Opens a bitcask backed by the given directory.
  def initialize(dir)
    @dir = dir
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
end
