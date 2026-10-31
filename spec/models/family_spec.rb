require "rails_helper"

RSpec.describe Family do
  describe "#answered?" do
    it "follows answered_at" do
      expect(create(:family, :answered)).to be_answered
      expect(create(:family)).not_to be_answered
    end
  end

  describe "destroying one" do
    it "takes its members with it" do
      family = create(:family)
      create_list(:family_member, 2, family:)

      expect { family.destroy }.to change(FamilyMember, :count).by(-2)
    end
  end

  describe "searching with Ransack" do
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
