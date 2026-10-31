require "rails_helper"

RSpec.describe FamilyMember do
  it "belongs to a family" do
    expect(build(:family_member, family: nil)).not_to be_valid
  end

  describe "the unique index on email" do
    it "refuses a duplicate address at the database level" do
      create(:family_member, email: "melanie@exemple.fr")

      expect { create(:family_member, email: "melanie@exemple.fr") }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "lets any number of members have no address" do
      members = create_list(:family_member, 3)

      expect(members.map(&:email)).to all(be_nil)
    end
  end
end
