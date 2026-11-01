require "rails_helper"

RSpec.describe Family do
  subject(:family) { create(:family) }

  describe "#answered?" do
    it "says no while a family has no members at all" do
      expect(family).not_to be_answered
    end

    it "says no while one member is still unanswered" do
      create(:family_member, :coming, family:)
      create(:family_member, family:)

      expect(family).not_to be_answered
    end

    it "says yes once every member has an answer, refusals included" do
      expect(create(:family, :answered)).to be_answered
    end
  end

  describe ".answered" do
    let!(:answered) { create(:family, :answered) }
    let!(:partly) { create(:family) }

    before do
      create(:family_member, :coming, family: partly)
      create(:family_member, family: partly)
    end

    it "returns the families the predicate calls answered, and only those" do
      expect(described_class.answered).to contain_exactly(answered)
      expect(described_class.all.select(&:answered?)).to contain_exactly(answered)
    end

    it "leaves out a family with no members" do
      expect(described_class.answered).not_to include(family)
    end
  end

  describe "#destroy" do
    before { create_list(:family_member, 2, family:) }

    it "takes its members with it" do
      expect { family.destroy }.to change(FamilyMember, :count).by(-2)
    end
  end

  describe ".ransack" do
    let!(:melchior) { create(:family, name: "Melchior") }
    let!(:dubois) { create(:family, name: "Dubois") }

    def matching(term) = described_class.ransack(Family::SEARCH_PREDICATE => term).result(distinct: true)

    before do
      create(:family_member, family: melchior, first_name: "Sylvain")
      create(:family_member, family: dubois, first_name: "Lucas", email: "helene.dubois@exemple.fr")
    end

    it "finds a family by its own name" do
      expect(matching("melch")).to contain_exactly(melchior)
    end

    it "finds a family by a member's first name" do
      expect(matching("lucas")).to contain_exactly(dubois)
    end

    it "finds a family by a member's email" do
      expect(matching("helene.dubois@exemple.fr")).to contain_exactly(dubois)
    end

    it "lists a family once however many of its members match" do
      create(:family_member, family: melchior, first_name: "Melchior")

      expect(matching("melchior")).to contain_exactly(melchior)
    end

    it "ignores the case of the term" do
      expect(matching("MELCH")).to contain_exactly(melchior)
    end

    it "treats a wildcard as a literal character" do
      expect(matching("%")).to be_empty
    end
  end
end
