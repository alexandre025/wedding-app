class Rsvp::LinkRequestForm < ApplicationForm
  attribute :email

  after_assign_form_attributes :normalize

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  def perform
    family_member = FamilyMember.find_by(email:)

    if family_member
      RsvpMailer.with(family_member:).link.deliver_later
    else
      errors.add(:email, :unknown)
      false
    end
  end

  private
    def normalize
      self.email = email.to_s.strip.downcase
    end
end
