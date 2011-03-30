$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../bin')
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../data')

require "rubygems"
require "bundler/setup"

require 'aruba/cucumber'

def usage_information
  <<-EOS
Usage:
	./cheap_tourist_fast_tourist [options] data/input.txt

Options:
    -h, --help      Print this help message
  EOS
end