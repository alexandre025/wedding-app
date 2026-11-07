require "rails_helper"

RSpec.describe RsvpHelper do
  describe "#rsvp_diet_line" do
    let(:diet) { Rsvp::AnswerPresenter::Diet.new("Mélanie", true, true, "Arachides") }

    it "names the guest and every requirement" do
      details = [
        I18n.t("rsvp.answers.show.vegetarian"),
        I18n.t("rsvp.answers.show.no_alcohol"),
        I18n.t("rsvp.answers.show.allergies", allergies: "Arachides")
      ].to_sentence

      expect(helper.rsvp_diet_line(diet)).to eq(I18n.t("rsvp.answers.show.diet_line", name: "Mélanie", details:))
    end
  end
end
