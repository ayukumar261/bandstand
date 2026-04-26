# frozen_string_literal: true

require 'securerandom'
require 'semantic_logger'

class RequestLogger
  LOGGER = SemanticLogger['Request']

  def initialize(app)
    @app = app
  end

  def call(env)
    req_id = env['HTTP_X_REQUEST_ID'] || SecureRandom.uuid
    env['HTTP_X_REQUEST_ID'] = req_id
    status = headers = body = nil

    SemanticLogger.tagged(request_id: req_id) do
      begin
        status, headers, body = @app.call(env)
      rescue StandardError => e
        LOGGER.error('Unhandled exception', exception: e)
        raise
      ensure
        if status
          headers ||= {}
          headers['X-Request-Id'] = req_id
        end
      end
    end

    [status, headers, body]
  end
end
