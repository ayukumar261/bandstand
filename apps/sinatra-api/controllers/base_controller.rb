# frozen_string_literal: true

require 'sinatra/base'
require 'sequel'
require 'json'

# Base Controller
class BaseController < Sinatra::Base
  configure do
    set :show_exceptions, false
    set :raise_errors, false
    set :dump_errors, true
  end

  before { content_type :json }

  helpers do
    def json_params
      @json_params ||= begin
        raw = request.body.read
        raw.empty? ? {} : JSON.parse(raw)
      end
    end
  end

  error Sequel::NoMatchingRow do
    status 404
    { error: 'not_found' }.to_json
  end

  error Sequel::ValidationFailed do |e|
    status 422
    { error: 'validation_failed', details: e.errors }.to_json
  end

  error JSON::ParserError do
    status 400
    { error: 'invalid_json' }.to_json
  end
end
