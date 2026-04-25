# frozen_string_literal: true

require 'semantic_logger'

$stdout.sync = true

SemanticLogger.default_level = (ENV['LOG_LEVEL'] || 'info').to_sym
formatter = ENV['RACK_ENV'] == 'production' ? :json : :color
SemanticLogger.add_appender(io: $stdout, formatter: formatter)
