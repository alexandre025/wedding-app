class Admin::FamilyMemberForm < ApplicationForm
  proxy_for FamilyMember, :@family_member

  attribute :first_name
  attribute :email
  attribute :age_group, default: "adult"

  after_assign_form_attributes :normalize

  validates :first_name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  validates :age_group, inclusion: { in: FamilyMember::AGE_GROUPS }
  validate :email_is_free

  def setup(family_member)
    @family_member = family_member
    self.first_name = family_member.first_name
    self.email = family_member.email
    self.age_group = family_member.age_group
  end

  def perform
    @family_member.first_name = first_name
    @family_member.email = email
    @family_member.age_group = age_group

    @family_member.save!
  end

  private
    def normalize
      self.first_name = first_name&.strip
      self.email = email&.strip&.downcase.presence
    end

    def email_is_free
      return if email.blank?

      others = FamilyMember.where(email:)
      others = others.where.not(id: @family_member.id) if @family_member.persisted?

      errors.add(:email, :taken) if others.exists?
    end
end
