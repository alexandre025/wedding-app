class Admin::FamilyMemberForm < ApplicationForm
  proxy_for FamilyMember, :@family_member

  attribute :first_name
  attribute :email

  after_assign_form_attributes :normalize

  validates :first_name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  validate :email_is_free

  def setup(family_member)
    @family_member = family_member
    self.first_name = family_member.first_name
    self.email = family_member.email
  end

  def perform
    @family_member.first_name = first_name
    @family_member.email = email

    @family_member.save || add_errors_from(@family_member)
  end

  private
    def normalize
      self.first_name = first_name&.strip
      self.email = email&.strip&.downcase.presence
    end

    def email_is_free
      return if email.blank?

      taken = FamilyMember.where(email: email).where.not(id: @family_member.id).exists?
      errors.add(:email, :taken) if taken
    end
end
