require 'rspec/autorun'
require "rspec/expectations"
require 'webmock/rspec'
require "json"
require 'rest-client'
require "moneta"

require "logger"
$logger = Logger.new(STDERR)

require File.expand_path('../../lib/divulgence', __FILE__)
