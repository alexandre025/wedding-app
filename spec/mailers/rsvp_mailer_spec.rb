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

    it "carries a link that opens the family's form" do
      token = mail.text_part.body.decoded[%r{/rsvp/([^/\s]+)/edit}, 1]

      expect(Family.find_signed(token, purpose: :rsvp)).to eq(family)
    end
  end
end
