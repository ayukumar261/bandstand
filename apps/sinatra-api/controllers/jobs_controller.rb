# frozen_string_literal: true

require_relative './base_controller'
require_relative '../models/job'

# Sinatra Controller
class JobsController < BaseController
  ALLOWED_FIELDS = %i[company_id title description type location].freeze

  get '/jobs' do
    Job.order(:id).all.to_json
  end

  post '/jobs' do
    job = Job.new
    job.set_fields(json_params, ALLOWED_FIELDS, missing: :skip)
    job.save(raise_on_failure: true)
    status 201
    job.to_json
  end

  get '/jobs/:id' do
    Job.with_pk!(params[:id]).to_json
  end

  patch '/jobs/:id' do
    job = Job.with_pk!(params[:id])
    job.set_fields(json_params, ALLOWED_FIELDS, missing: :skip)
    job.save(raise_on_failure: true)
    job.to_json
  end

  delete '/jobs/:id' do
    Job.with_pk!(params[:id]).destroy
    status 204
    body ''
  end
end
