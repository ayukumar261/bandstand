# frozen_string_literal: true

require 'rack'

class BearerAuth
  EXEMPT_PATHS = %w[/health /health/db].freeze

  def initialize(app)
    @app = app
    @token = ENV.fetch('API_KEY')
  end

  def call(env)
    return @app.call(env) if EXEMPT_PATHS.include?(env['PATH_INFO'])

    provided = bearer_token(env)
    if provided && Rack::Utils.secure_compare(@token, provided)
      @app.call(env)
    else
      [401, { 'Content-Type' => 'application/json' }, ['{"error":"unauthorized"}']]
    end
  end

  private

  def bearer_token(env)
    header = env['HTTP_AUTHORIZATION'] || ''
    header.start_with?('Bearer ') ? header.delete_prefix('Bearer ') : nil
  end
end
