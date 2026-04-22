# frozen_string_literal: true

require 'sequel'
require 'dotenv/load'

DB = Sequel.connect(ENV.fetch('DATABASE_URL'))

Sequel::Model.plugin :timestamps, update_on_create: true
Sequel::Model.plugin :json_serializer
