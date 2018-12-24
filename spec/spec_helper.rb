# -*- encoding: utf-8; mode: ruby -*-

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

require 'bundler'
Bundler.setup(:default, :test)


require "rspec"
require "json"
require "rabbitmq/http/client"
require "bunny"
require "rantly"
