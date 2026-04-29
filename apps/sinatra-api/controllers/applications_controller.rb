# frozen_string_literal: true

require_relative './base_controller'
require_relative '../models/application'

# Sinatra Controller
class ApplicationsController < BaseController
  ALLOWED_FIELDS = %i[job_id name phone email].freeze

  get '/applications' do
    Application.order(:id).all.to_json
  end

  post '/applications' do
    application = Application.new
    application.set_fields(json_params, ALLOWED_FIELDS, missing: :skip)
    application.save(raise_on_failure: true)
    status 201
    application.to_json
  end

  get '/applications/:id' do
    Application.with_pk!(params[:id]).to_json
  end

  patch '/applications/:id' do
    application = Application.with_pk!(params[:id])
    application.set_fields(json_params, ALLOWED_FIELDS, missing: :skip)
    application.save(raise_on_failure: true)
    application.to_json
  end

  delete '/applications/:id' do
    Application.with_pk!(params[:id]).destroy
    status 204
    body ''
  end
end
