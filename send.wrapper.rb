#!/usr/bin/env ruby

require 'pathname'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path("../Gemfile",
  Pathname.new(__FILE__).realpath)

require 'rubygems'
require 'bundler/setup'

$LOAD_PATH.unshift File.dirname(Pathname.new(__FILE__).realpath)
load 'send.rb'
