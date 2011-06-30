#!/usr/bin/env ruby

require 'rubygems'
require 'bacon'
require "#{File.expand_path(File.dirname(__FILE__))}/../lib/bitcask"

unless ARGV.first
  puts "I need a bitcask directory."
  exit 1
end

Bacon.summary_on_exit

describe 'Bitcask GC' do
  def count(k)
    c = 0
    ObjectSpace.each_object(k) do |x|
      c += 1
    end
    c
  end

  def all(k)
    os = []
    ObjectSpace.each_object(k) do |x|
      os << x
    end
    os
  end
    
  def fhs
    `lsof -p #{Process.pid} 2>/dev/null`.split("\n").map do |line|
      line.chomp.split("\s", 9).last
    end.select do |e|
      e[File.expand_path(ARGV.first)]
    end.size
  end

  it 'test GC tests' do
    class Foo; end
    x = Foo.new
    count(Foo).should == 1

    x = nil
    GC.start
    count(Foo).should == 0    
  end
 
  should 'GC an unloaded bitcask' do
    x = Bitcask.new ARGV.first
    count(Bitcask).should == 1
    x = nil
    GC.start
    count(Bitcask).should == 0
  end

  should 'GC a bitcask and datafiles' do
    x = Bitcask.new ARGV.first
    x.data_files
    
    count(Bitcask::DataFile).should > 0

    x = nil
    GC.start

    count(Bitcask::DataFile).should == 0
    count(Bitcask).should == 0
  end

  should 'close filehandles from an unloaded bitcask at GC' do
    f1 = fhs

    b = Bitcask.new ARGV.first
    b.data_files
    
    f2 = fhs
    f2.should > f1

    # When removed, the datafiles should be GCed.
    b = nil
    GC.start

    f3 = fhs
    f3.should < f2
    f3.should == f1
  end

  should 'close filehandles from a loaded bitcask at GC' do
    f1 = fhs
    b = Bitcask.new ARGV.first
    b.load

    f2 = fhs
    f2.should > f1

    b = nil
    GC.start

    f3 = fhs
    f3.should < f2
    f3.should == f1
  end
end
