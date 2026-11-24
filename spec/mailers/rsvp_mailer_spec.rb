require "rails_helper"

RSpec.describe RsvpMailer do
  describe "#link" do
    subject(:mail) { described_class.with(family_member: melanie).link }

    let(:family) { create(:family, name: "Melchior") }
    let(:melanie) { create(:family_member, :with_email, family:, first_name: "Mélanie") }

    it "goes to the member who asked" do
      expect(mail.to).to eq([ melanie.email ])
      expect(mail.subject).to eq(I18n.t("rsvp_mailer.link.subject"))
    end

    it "sends replies to the couple" do
      expect(mail.reply_to).to eq(Rails.application.config.x.mail_reply_to)
    end

    it "carries a link that opens the family's form" do
      token = mail.text_part.body.decoded[%r{/rsvp/([^/\s]+)/edit}, 1]

      expect(Family.find_signed(token, purpose: :rsvp)).to eq(family)
    end

    it "lays the message out in the invitation's frame" do
      html = Nokogiri::HTML(mail.html_part.body.decoded)
      token = mail.text_part.body.decoded[%r{/rsvp/([^/\s]+)/edit}, 1]

      expect(html.at_css("h1").text.strip).to eq(I18n.t("rsvp_mailer.link.title"))
      expect(html.at_css("a.mail-button").text.strip).to eq(I18n.t("rsvp_mailer.link.cta"))
      expect(html.at_css("a.mail-button")["href"]).to end_with("/rsvp/#{token}/edit")
      expect(html.text).to include(I18n.t("rsvp_mailer.link.preheader"), I18n.t("mailer.footer.reply"))
    end
  end
end
