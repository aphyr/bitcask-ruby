class Bitcask::Keydir < Hash
  Entry = Struct.new :file_id, :value_sz, :value_pos, :tstamp

  attr_accessor :data_files
  def initialize(*a)
    super *a

    @data_files = []
  end
end
