#!/usr/bin/env ruby

require 'rubygems'
require 'bacon'
require 'bert'
require 'pp'
require "#{File.expand_path(File.dirname(__FILE__))}/../lib/bitcask"

unless ARGV.first
  puts "I need a bitcask directory."
  exit 1
end

Bacon.summary_on_exit

describe 'Bitcask' do
  before do
    @b = Bitcask.new ARGV.first
    @f = @b.data_files.first

  end

  should 'start at 0' do
    @f.pos.should == 0
  end

  should 'seek' do
    @f.seek 1
    @f.pos.should == 1
  end

  should 'rewind' do
    @f.seek 1
    @f.rewind
    @f.pos.should == 0
  end

  should 'read' do
    entries = []
  
    @f.pos.should == 0 
    entries << @f.read
    entries[0].should.be.kind_of? Array
    entries[0].size.should == 2
    entries[0][0].should.be.kind_of? String
    entries[0][1].should.be.kind_of? String
    @f.pos.should > 0
  end

  should 'checksum' do
    @f.seek 1
    lambda { @f.read }.should.raise Bitcask::ChecksumError
  end

  should '[]' do
    one_pos = @f.pos
    one = @f.read
    two_pos = @f.pos
    two = @f.read

    @f[two_pos].should == two
    @f[one_pos].should == one
  end

  should 'each' do
    c = 0
    t1 = Time.now
    
    @f.each do |k,v|
      k.should.be.kind_of? String
      c += 1
    end

    rate = c.to_f / (Time.now - t1)
    rate.should > 5000
    puts
    puts "  #{c} values at #{rate}/s"
  end
end
