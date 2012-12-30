# -*- encoding : utf-8 -*-

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'data/cache'
  c.hook_into :faraday
  c.allow_http_connections_when_no_cassette = true
end