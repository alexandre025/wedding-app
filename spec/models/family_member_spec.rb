require "rails_helper"

RSpec.describe FamilyMember do
  it "belongs to a family" do
    expect(build(:family_member, family: nil)).not_to be_valid
  end

  describe "the options" do
    it "leaves attendance unanswered until someone answers" do
      expect(create(:family_member).attends).to be_nil
    end

    it "keeps a refusal apart from an unanswered question" do
      expect(create(:family_member, :not_coming).attends).to be(false)
      expect(create(:family_member, :coming).attends).to be(true)
    end

    it "starts every one of them off" do
      member = create(:family_member)

      expect(member.no_alcohol).to be(false)
      expect(member.attends_brunch).to be(false)
      expect(member.attends_run).to be(false)
      expect(member.allergies).to be_nil
    end

    it "keeps them apart from one another" do
      member = create(:family_member, :runner)

      expect(member.attends_run).to be(true)
      expect(member.attends_brunch).to be(false)
    end
  end

  describe "#adult?" do
    it "is true for an adult alone" do
      expect(build(:family_member)).to be_adult
      expect(build(:family_member, :teen)).not_to be_adult
      expect(build(:family_member, :kid)).not_to be_adult
      expect(build(:family_member, :baby)).not_to be_adult
    end
  end

  describe "#child?" do
    it "counts a baby and a kid, but not a teenager" do
      expect(build(:family_member, :baby)).to be_child
      expect(build(:family_member, :kid)).to be_child
      expect(build(:family_member, :teen)).not_to be_child
      expect(build(:family_member)).not_to be_child
    end
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
