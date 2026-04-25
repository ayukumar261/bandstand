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
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    status = headers = body = nil

    SemanticLogger.tagged(request_id: req_id) do
      begin
        status, headers, body = @app.call(env)
      rescue StandardError => e
        LOGGER.error('Unhandled exception', exception: e)
        raise
      ensure
        duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round(2)
        if status
          headers ||= {}
          headers['X-Request-Id'] = req_id
        end
        LOGGER.info('request',
                    method:      env['REQUEST_METHOD'],
                    path:        env['PATH_INFO'],
                    status:      status,
                    duration_ms: duration_ms,
                    remote_ip:   env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_ADDR'],
                    user_agent:  env['HTTP_USER_AGENT'])
      end
    end

    [status, headers, body]
  end
end
