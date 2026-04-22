# frozen_string_literal: true

require_relative './app'
require_relative './controllers/companies_controller'
require_relative './controllers/jobs_controller'

use CompaniesController
use JobsController
run App
