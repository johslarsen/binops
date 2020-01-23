#!/usr/bin/env ruby
require 'simplecov'
SimpleCov.start do
  root File.realpath("#{File.dirname(__FILE__)}/..")
end

require 'minitest/autorun'
