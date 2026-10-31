class FamilyMember < ApplicationRecord
  belongs_to :family

  def self.ransackable_attributes(_auth_object = nil) = [ "first_name", "email" ]

  def self.ransackable_associations(_auth_object = nil) = []
end
