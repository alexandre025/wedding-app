class FamilyMember < ApplicationRecord
  AGE_GROUPS = [
    BABY = "baby",
    KID = "kid",
    TEEN = "teen",
    ADULT = "adult"
  ].freeze

  CHILD_AGE_GROUPS = [ BABY, KID ].freeze

  belongs_to :family

  validates :email, uniqueness: { case_sensitive: false }, allow_nil: true

  def self.ransackable_attributes(_auth_object = nil) = [ "first_name", "email" ]

  def self.ransackable_associations(_auth_object = nil) = []

  def child? = CHILD_AGE_GROUPS.include?(age_group)

  def adult? = age_group == ADULT
end
