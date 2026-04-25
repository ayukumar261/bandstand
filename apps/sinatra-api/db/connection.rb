# frozen_string_literal: true

require 'sequel'
require 'dotenv/load'
require_relative '../lib/logger'

DB = Sequel.connect(ENV.fetch('DATABASE_URL'))
DB.loggers << SemanticLogger['Sequel']
DB.sql_log_level = :debug

Sequel::Model.plugin :timestamps, update_on_create: true
Sequel::Model.plugin :json_serializer
