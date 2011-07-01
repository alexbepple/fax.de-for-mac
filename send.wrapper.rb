#!/usr/bin/env ruby

require 'pathname'
app_dir = File.dirname(Pathname.new(__FILE__).realpath)

ENV['BUNDLE_GEMFILE'] ||= File.join(app_dir, 'Gemfile')

require 'rubygems'
require 'bundler/setup'

$LOAD_PATH.unshift app_dir
load 'send.rb'
