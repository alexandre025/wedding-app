class RsvpMailer < ApplicationMailer
  def link
    @family_member = params[:family_member]
    @family = @family_member.family
    @url = edit_rsvp_answer_url(@family.signed_id(purpose: :rsvp))

    mail to: @family_member.email, subject: t("rsvp_mailer.link.subject")
  end
end
