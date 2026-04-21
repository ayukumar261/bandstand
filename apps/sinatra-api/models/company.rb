# frozen_string_literal: true

require_relative '../db/connection'

# Sequel ORM Model
class Company < Sequel::Model
  one_to_many :jobs

  def validate
    super
    errors.add(:name, "can't be blank") if name.nil? || name.empty?
  end
end
