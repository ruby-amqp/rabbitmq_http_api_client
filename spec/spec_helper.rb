# -*- encoding: utf-8; mode: ruby -*-

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

require 'bundler'
Bundler.setup(:default, :test)


require "effin_utf8"
require "rspec"
require "superintendent"
require "bunny"
