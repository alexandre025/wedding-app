class FamilyMember < ApplicationRecord
  AGE_GROUPS = [
    BABY = "baby",
    KID = "kid",
    TEEN = "teen",
    ADULT = "adult"
  ].freeze

  belongs_to :family

  validates :email, uniqueness: { case_sensitive: false }, allow_nil: true

  def self.ransackable_attributes(_auth_object = nil) = [ "first_name", "email" ]

  def self.ransackable_associations(_auth_object = nil) = []
end
