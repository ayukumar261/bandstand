# frozen_string_literal: true

require 'sinatra/base'
require 'json'
require 'time'

class App < Sinatra::Base
  configure do
    set :bind, '0.0.0.0'
    set :port, 4567
    set :show_exceptions, false
    set :raise_errors, false
    set :dump_errors, true
  end

  before { content_type :json }

  get '/health' do
    { status: 'ok', service: 'api', time: Time.now.utc.iso8601 }.to_json
  end

  not_found do
    { error: 'not_found' }.to_json
  end
end
