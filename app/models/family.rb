class Family < ApplicationRecord
  SEARCH_PREDICATE = :name_or_family_members_first_name_or_family_members_email_i_cont

  has_many :family_members, -> { order(:id) }, dependent: :destroy

  scope :pending, -> { where(id: FamilyMember.where(attends: nil).select(:family_id)) }

  scope :answered, -> { where(id: FamilyMember.select(:family_id)).where.not(id: pending.select(:id)) }

  def self.ransackable_attributes(_auth_object = nil) = [ "name" ]

  def self.ransackable_associations(_auth_object = nil) = [ "family_members" ]

  def answered? = family_members.any? && family_members.none? { |member| member.attends.nil? }
end
