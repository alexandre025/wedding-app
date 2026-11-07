require "rails_helper"

RSpec.describe Rsvp::AnswerForm do
  subject(:form) { described_class.new(family.reload) }

  let(:family) { create(:family) }
  let!(:melanie) { create(:family_member, family:, first_name: "Mélanie") }
  let!(:celie) { create(:family_member, :teen, family:, first_name: "Célie") }
  let!(:lena) { create(:family_member, :kid, family:, first_name: "Léna") }

  let(:melanie_answer) { { attends: "true", no_alcohol: "1", vegetarian: "0", attends_run: "1", attends_brunch: "1" } }
  let(:celie_answer) { { attends: "true", no_alcohol: "0", attends_run: "1" } }
  let(:lena_answer) { { attends: "false" } }
  let(:params) do
    {
      members: { melanie.id.to_s => melanie_answer, celie.id.to_s => celie_answer, lena.id.to_s => lena_answer },
      song: "  Les Champs-Élysées  "
    }
  end

  describe ".new" do
    subject(:form) { described_class.new(family.reload) }

    let(:family) { create(:family, :with_song) }
    let!(:melanie) { create(:family_member, :coming, :vegetarian, family:) }

    it "reads the stored answers back" do
      expect(form.song).to eq("Les Champs-Élysées, Joe Dassin")
      expect(form.member_forms.first).to have_attributes(attends: true, vegetarian: true)
    end
  end

  describe "#submit" do
    it "records every member's answer and the song" do
      expect(form.submit(params)).to be(true)

      expect(melanie.reload).to have_attributes(attends: true, no_alcohol: true, attends_run: true, attends_brunch: true)
      expect(lena.reload.attends).to be(false)
      expect(family.reload.song).to eq("Les Champs-Élysées")
    end

    it "keeps a teenager off alcohol whatever was submitted" do
      form.submit(params)

      expect(celie.reload).to have_attributes(no_alcohol: true, attends_run: true)
    end

    context "when a child is signed up for the run" do
      let(:lena_answer) { { attends: "true", attends_run: "1" } }

      it "drops the run" do
        form.submit(params)

        expect(lena.reload.attends_run).to be(false)
      end
    end

    context "when an absent member's hidden options are still submitted" do
      let(:melanie_answer) { super().merge(attends: "false", allergies: "Arachides") }

      it "clears them" do
        form.submit(params)

        expect(melanie.reload).to have_attributes(attends: false, no_alcohol: false, attends_run: false,
          attends_brunch: false, allergies: nil)
      end
    end

    context "when nobody comes" do
      let(:melanie_answer) { { attends: "false" } }
      let(:celie_answer) { { attends: "false" } }

      it "keeps no song" do
        form.submit(params)

        expect(family.reload.song).to be_nil
      end
    end

    context "when a member is left unanswered" do
      let(:params) { super().merge(members: { melanie.id.to_s => melanie_answer }) }

      it "saves nobody and says so" do
        expect(form.submit(params)).to be(false)
        expect(form.errors.of_kind?(:base, :unanswered)).to be(true)
        expect(melanie.reload.attends).to be_nil
      end
    end

    context "when members arrive as a string" do
      let(:params) { { members: "tout le monde" } }

      it "treats every member as unanswered" do
        expect(form.submit(params)).to be(false)
      end
    end
  end
end
