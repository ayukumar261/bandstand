# frozen_string_literal: true

require 'sinatra/base'
require 'json'
require 'time'
require 'semantic_logger'

class App < Sinatra::Base
  configure do
    set :bind, '0.0.0.0'
    set :show_exceptions, false
    set :raise_errors, false
    set :dump_errors, false
    set :logging, false
  end

  LOGGER = SemanticLogger['App']

  before { content_type :json }

  get '/health' do
    { status: 'ok', service: 'api', time: Time.now.utc.iso8601 }.to_json
  end

  not_found do
    { error: 'not_found' }.to_json
  end

  error StandardError do |e|
    LOGGER.error('unhandled_exception', exception: e)
    status 500
    { error: 'internal_server_error' }.to_json
  end
end
