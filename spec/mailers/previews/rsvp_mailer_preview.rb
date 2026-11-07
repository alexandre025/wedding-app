class RsvpMailerPreview < ActionMailer::Preview
  def link
    RsvpMailer.with(family_member: FamilyMember.where.not(email: nil).first).link
  end
end
