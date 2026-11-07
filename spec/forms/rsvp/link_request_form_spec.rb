require "rails_helper"

RSpec.describe Rsvp::LinkRequestForm do
  subject(:form) { described_class.new }

  let!(:melanie) { create(:family_member, first_name: "Mélanie", email: "melanie@exemple.fr") }

  describe "#submit" do
    it "emails the family's link to a known address" do
      expect { form.submit(email: "melanie@exemple.fr") }
        .to have_enqueued_mail(RsvpMailer, :link).with(params: { family_member: melanie }, args: [])
    end

    it "matches the address whatever its case and padding" do
      expect(form.submit(email: "  Melanie@Exemple.FR ")).to be(true)
    end

    it "refuses a malformed address" do
      expect(form.submit(email: "melanie@")).to be(false)
      expect(form.errors.of_kind?(:email, :invalid)).to be(true)
    end

    it "refuses an address missing from the guest list, without sending anything" do
      expect { form.submit(email: "inconnu@exemple.fr") }.not_to have_enqueued_mail
      expect(form.errors.of_kind?(:email, :unknown)).to be(true)
    end
  end
end
