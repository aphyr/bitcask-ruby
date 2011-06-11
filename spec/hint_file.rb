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

describe 'HintFile' do
  before do
    @b = Bitcask.new ARGV.first
    @f = @b.data_files.first
    @h = @f.hint_file
  end

  should 'start at 0' do
    @h.pos.should == 0
  end

  should 'seek' do
    @h.seek 1
    @h.pos.should == 1
  end

  should 'rewind' do
    @h.seek 1
    @h.rewind
    @h.pos.should == 0
  end

  should 'read' do
    entries = []
  
    @h.pos.should == 0 
    entries << @h.read
    
    entries[0].should.be.kind_of Bitcask::HintFile::Entry
    entries[0].key.should.be.kind_of? String
    entries[0].value_pos.should.be.kind_of? Integer
    entries[0].value_sz.should.be.kind_of? Integer
    entries[0].tstamp.should.be.kind_of? Integer

    @h.pos.should > 0
  end

  should '[]' do
    one_pos = @h.pos
    one = @h.read
    two_pos = @h.pos
    two = @h.read

    @h[two_pos].should == two
    @h[one_pos].should == one
  end

  should 'each' do
    c = 0
    t1 = Time.now
    
    @h.each do |k,v|
      k.should.be.kind_of? Bitcask::HintFile::Entry
      c += 1
    end

    rate = c.to_f / (Time.now - t1)
    rate.should > 1000
    puts
    puts "  #{c} values at #{rate}/s"
  end

  should 'refer to valid entries in the data file' do
    @h.first(10).should.all do |hint|
      data = @f[hint.value_pos, hint.value_sz]
      hint['key'].should == data['key']
      hint['tstamp'].should == data['tstamp']
    end
  end
end
