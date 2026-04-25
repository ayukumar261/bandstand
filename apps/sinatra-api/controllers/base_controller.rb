# frozen_string_literal: true

require 'sinatra/base'
require 'sequel'
require 'json'
require 'semantic_logger'

# Base Controller
class BaseController < Sinatra::Base
  configure do
    set :show_exceptions, false
    set :raise_errors, false
    set :dump_errors, false
    set :logging, false
  end

  LOGGER = SemanticLogger['BaseController']

  before { content_type :json }

  helpers do
    def json_params
      @json_params ||= begin
        raw = request.body.read
        raw.empty? ? {} : JSON.parse(raw)
      end
    end
  end

  error Sequel::NoMatchingRow do |e|
    LOGGER.warn('not_found', exception: e)
    status 404
    { error: 'not_found' }.to_json
  end

  error Sequel::ValidationFailed do |e|
    LOGGER.warn('validation_failed', exception: e)
    status 422
    { error: 'validation_failed', details: e.errors }.to_json
  end

  error JSON::ParserError do |e|
    LOGGER.warn('invalid_json', exception: e)
    status 400
    { error: 'invalid_json' }.to_json
  end

  error StandardError do |e|
    LOGGER.error('unhandled_exception', exception: e)
    status 500
    { error: 'internal_server_error' }.to_json
  end
end
