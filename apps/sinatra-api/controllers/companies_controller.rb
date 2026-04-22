# frozen_string_literal: true

require_relative './base_controller'
require_relative '../models/company'

# Sinatra Controller
class CompaniesController < BaseController
  ALLOWED_FIELDS = %i[name website industry location size].freeze

  get '/companies' do
    Company.order(:id).all.to_json
  end

  post '/companies' do
    company = Company.new
    company.set_fields(json_params, ALLOWED_FIELDS, missing: :skip)
    company.save(raise_on_failure: true)
    status 201
    company.to_json
  end

  get '/companies/:id' do
    Company.with_pk!(params[:id]).to_json
  end

  patch '/companies/:id' do
    company = Company.with_pk!(params[:id])
    company.set_fields(json_params, ALLOWED_FIELDS, missing: :skip)
    company.save(raise_on_failure: true)
    company.to_json
  end

  delete '/companies/:id' do
    Company.with_pk!(params[:id]).destroy
    status 204
    body ''
  end
end
