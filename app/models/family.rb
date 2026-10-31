class Family < ApplicationRecord
  SEARCH_PREDICATE = :name_or_family_members_first_name_or_family_members_email_i_cont

  has_many :family_members, -> { order(:id) }, dependent: :destroy

  def self.ransackable_attributes(_auth_object = nil) = [ "name" ]

  def self.ransackable_associations(_auth_object = nil) = [ "family_members" ]

  def answered? = answered_at.present?
end
