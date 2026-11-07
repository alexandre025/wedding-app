class Rsvp::MemberAnswerForm < ApplicationForm
  proxy_for FamilyMember, :@family_member

  attribute :attends, :boolean
  attribute :no_alcohol, :boolean, default: false
  attribute :vegetarian, :boolean, default: false
  attribute :attends_brunch, :boolean, default: false
  attribute :attends_run, :boolean, default: false
  attribute :allergies

  after_assign_form_attributes :normalize

  attr_reader :family_member

  delegate :first_name, :adult?, :child?, to: :family_member

  def setup(family_member)
    @family_member = family_member
    self.attends = family_member.attends
    self.no_alcohol = family_member.no_alcohol
    self.vegetarian = family_member.vegetarian
    self.attends_brunch = family_member.attends_brunch
    self.attends_run = family_member.attends_run
    self.allergies = family_member.allergies
  end

  def answered? = !attends.nil?

  def perform
    @family_member.attends = attends
    @family_member.no_alcohol = no_alcohol
    @family_member.vegetarian = vegetarian
    @family_member.attends_brunch = attends_brunch
    @family_member.attends_run = attends_run
    @family_member.allergies = allergies

    @family_member.save!
  end

  private
    def normalize
      self.allergies = allergies&.strip.presence

      unless attends
        self.no_alcohol = false
        self.vegetarian = false
        self.attends_brunch = false
        self.attends_run = false
        self.allergies = nil
      end

      self.no_alcohol = true unless adult?
      self.attends_run = false if child?
    end
end
