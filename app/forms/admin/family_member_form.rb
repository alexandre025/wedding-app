class Admin::FamilyMemberForm < ApplicationForm
  proxy_for FamilyMember, :@family_member

  attribute :first_name
  attribute :email
  attribute :age_group, default: FamilyMember::ADULT
  attribute :attends, :boolean
  attribute :no_alcohol, :boolean, default: false
  attribute :vegetarian, :boolean, default: false
  attribute :attends_brunch, :boolean, default: false
  attribute :attends_run, :boolean, default: false
  attribute :allergies

  after_assign_form_attributes :normalize

  validates :first_name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  validates :age_group, inclusion: { in: FamilyMember::AGE_GROUPS }

  def setup(family_member)
    @family_member = family_member
    self.first_name = family_member.first_name
    self.email = family_member.email
    self.age_group = family_member.age_group
    self.attends = family_member.attends
    self.no_alcohol = family_member.no_alcohol
    self.vegetarian = family_member.vegetarian
    self.attends_brunch = family_member.attends_brunch
    self.attends_run = family_member.attends_run
    self.allergies = family_member.allergies
  end

  def perform
    @family_member.first_name = first_name
    @family_member.email = email
    @family_member.age_group = age_group
    @family_member.attends = attends
    @family_member.no_alcohol = no_alcohol
    @family_member.vegetarian = vegetarian
    @family_member.attends_brunch = attends_brunch
    @family_member.attends_run = attends_run
    @family_member.allergies = allergies

    @family_member.save || add_errors_from(@family_member)
  end

  private
    def normalize
      self.first_name = first_name&.strip
      self.email = email&.strip&.downcase.presence
      self.allergies = allergies&.strip.presence

      self.no_alcohol = true unless age_group == FamilyMember::ADULT
      self.attends_run = false if FamilyMember::CHILD_AGE_GROUPS.include?(age_group)
    end
end
