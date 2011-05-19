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
end
