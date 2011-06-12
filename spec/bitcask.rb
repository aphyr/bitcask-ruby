#!/usr/bin/env ruby

require 'rubygems'
require 'bacon'
require "#{File.expand_path(File.dirname(__FILE__))}/../lib/bitcask"

unless ARGV.first
  puts "I need a bitcask directory."
  exit 1
end

Bacon.summary_on_exit

describe 'Bitcask' do
  before do
    @b = Bitcask.new ARGV.first
  end

  should 'have DataFiles' do
    @b.data_files.should.be.kind_of? Array
    @b.data_files.first.should.be.kind_of? Bitcask::DataFile
  end

  it 'load_data_file' do
    @b.size.should == 0
    @b.load_data_file @b.data_files.first
    @b.size.should > 0

    @b.keydir.each do |key, index|
      data_file = @b.keydir.data_files[index.file_id]
      entry = data_file[index.value_pos, index.value_sz]
      entry.key.should == key
    end
  end

  it 'load_hint_file' do
    @b.load_hint_file @b.data_files.first.hint_file
    hinted_keydir = @b.keydir

    @b.keydir = Bitcask::Keydir.new
    @b.load_data_file @b.data_files.first
   
    hinted_keydir.should == @b.keydir
  end

  it '[]' do
    @b.load

    @b.keydir.keys.each do |key|
      e = @b[key]
      e.should.be.kind_of? Bitcask::DataFile::Entry
      e.key.should == key
      e.value.should.be.kind_of? String
      e.tstamp.should.be.kind_of? Integer
    end
  end

  it 'each' do
    @b.load

    @b.each do |entry|
      entry.should.be.kind_of? Bitcask::DataFile::Entry
      entry.key.should.be.kind_of? String
      entry.value.should.be.kind_of? String
    end
  end
end
