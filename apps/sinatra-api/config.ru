# frozen_string_literal: true

require_relative './lib/logger'
require_relative './lib/middleware/request_logger'
require_relative './app'
require_relative './controllers/companies_controller'
require_relative './controllers/jobs_controller'

use RequestLogger
use CompaniesController
use JobsController
run App
