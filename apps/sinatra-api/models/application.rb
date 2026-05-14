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
    errors.add(:email, 'is not a valid email address') if !email.nil? && !email.empty? && !email.match?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/)
    errors.add(:job_id, 'is required') if job_id.nil?
    errors.add(:job_id, 'does not exist') if !job_id.nil? && job.nil?
    errors.add(:phone, 'is not a valid phone number') if !phone.nil? && !phone.empty? && !phone.match?(/\A\+?[\d\s\-\(\)\.]{7,20}\z/)
  end
end
