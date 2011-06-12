Bitcask
=======

Utilities for reading the Bitcask file format. You can use this to recover
deleted values (before they are compacted), recover from a backup, list keys
to do read-repair when list-keys is malfunctioning, and so forth.

Install
-------

    $ gem install bitcask

Examples
--------

Open a bitcask.

    b = Bitcask.new '/var/lib/riak/bitcask/0'

Load the keydir, using hintfiles where possible.

    b.load

Get a specific entry:

    b['test'] #=> 'value_of_test'

Iterate over all values:

    b.each do |key, value|
      puts key
      puts value
    end

In Riak, these are erlang terms.

    b.each do |key, value|
      next if value == Bitcask::TOMBSTONE

      bucket, key = BERT.decode key
      value = BERT.decode value

      # Store the object's value in riak
      o = riak[bucket][key]
      o.raw_data = value.last
      o.store

      # Or dump the entire value to a file for later inspection.
      FileUtils.mkdir_p(bucket)
      File.open(File.join(bucket, key), 'w') do |out|
        out.write value.to_json
      end
    end

You can also work directly on the data files. Here's how to dump all keys and
values, in cron order, excluding tombstones. Data files go in cronological
order, so this is in effect replaying history since the last merge.

    b.data_files.each do |data_file|
      data_file.each do |entry|
        next if entry.value == Bitcask::TOMBSTONE
        puts entry.key
        puts entry.value
      end
    end

If you know the offset, you can retrieve it directly from a DataFile.

    data_file[0] # => Struct {:key => 'key', :value => 'value'}

And step through values one by one.

    data_file.read # => [k1, v1]
    data_file.read # => [k2, v2]

Seek, rewind, and pos are also supported.

You'd be surprised how fast this is. 10,000 values/sec, easy.

Status
------

Anyone who wants to expand this, feel free. I've been using it for emergency
recovery operations, but don't plan to reimplement bitcask in Ruby myself. I
welcome pull requests.

License
-------

This software was written by Kyle Kingsbury <aphyr@aphyr.com>, at Remixation,
Inc., for their iPad social video app "Showyou". Released under the MIT
license.
