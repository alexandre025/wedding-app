require "rails_helper"

RSpec.describe Rsvp::AnswerPresenter do
  subject(:answer) { described_class.new(family.reload) }

  let(:family) { create(:family, :with_song) }

  before do
    create(:family_member, :coming, :runner, :brunching, :teetotal, family:, first_name: "Mélanie")
    create(:family_member, :coming, :vegetarian, :brunching, family:, first_name: "Sylvain")
    create(:family_member, :teen, :coming, :with_allergies, family:, first_name: "Célie")
    create(:family_member, :kid, :not_coming, :vegetarian, family:, first_name: "Léna")
  end

  describe "#any_present?" do
    it { expect(answer.any_present?).to be(true) }
  end

  describe "#present_names" do
    it { expect(answer.present_names).to eq(%w[Mélanie Sylvain Célie]) }
  end

  describe "#absent_names" do
    it { expect(answer.absent_names).to eq(%w[Léna]) }
  end

  describe "#run_names" do
    it { expect(answer.run_names).to eq(%w[Mélanie]) }
  end

  describe "#brunch_names" do
    it { expect(answer.brunch_names).to eq(%w[Mélanie Sylvain]) }
  end

  describe "#song" do
    it { expect(answer.song).to eq("Les Champs-Élysées, Joe Dassin") }
  end

  describe "#diets" do
    it "lists the present members with something to tell the kitchen, leaving out a minor's enforced no-alcohol" do
      expect(answer.diets.map(&:to_a)).to eq([
        [ "Mélanie", false, true, nil ],
        [ "Sylvain", true, false, nil ],
        [ "Célie", false, false, "Arachides" ]
      ])
    end
  end
end
