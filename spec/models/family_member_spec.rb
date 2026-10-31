require "rails_helper"

RSpec.describe FamilyMember do
  it "belongs to a family" do
    expect(build(:family_member, family: nil)).not_to be_valid
  end

  describe "the email" do
    it "may be missing from any number of members" do
      create_list(:family_member, 3)

      expect(build(:family_member)).to be_valid
    end

    it "may not be held by two members, whichever families they are in" do
      create(:family_member, email: "melanie@exemple.fr")
      member = build(:family_member, family: create(:family), email: "melanie@exemple.fr")

      expect(member).not_to be_valid
      expect(member.errors[:email]).to eq([ I18n.t("errors.attributes.email.taken") ])
    end

    it "ignores case when comparing" do
      create(:family_member, email: "melanie@exemple.fr")

      expect(build(:family_member, email: "MELANIE@exemple.fr")).not_to be_valid
    end

    it "does not count a member's own address as taken" do
      member = create(:family_member, :with_email)

      expect(member).to be_valid
    end

    it "is backed by a unique index, not only the validation" do
      create(:family_member, email: "melanie@exemple.fr")
      duplicate = build(:family_member, email: "melanie@exemple.fr")

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
