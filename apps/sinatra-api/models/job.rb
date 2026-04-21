# frozen_string_literal: true

require_relative '../db/connection'

# Sequel ORM Model
class Job < Sequel::Model
  many_to_one :company

  def validate
    super
    errors.add(:title, "can't be blank") if title.nil? || title.empty?
    errors.add(:company_id, 'is required') if company_id.nil?
  end
end
