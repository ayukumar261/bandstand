# frozen_string_literal: true

require_relative '../db/connection'
require_relative 'job'

# Sequel ORM Model
class Application < Sequel::Model
  many_to_one :job

  def validate
    super
    errors.add(:name, "can't be blank") if name.nil? || name.empty?
    errors.add(:email, "can't be blank") if email.nil? || email.empty?
    errors.add(:job_id, 'is required') if job_id.nil?
    errors.add(:job_id, 'does not exist') if !job_id.nil? && job.nil?
  end
end
