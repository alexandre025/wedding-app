require "rails_helper"

RSpec.describe FamilyMember do
  subject(:member) { build(:family_member) }

  describe ".new" do
    it "leaves attendance unanswered until someone answers" do
      expect(member.attends).to be_nil
    end

    it "starts every option off" do
      expect(member).to have_attributes(no_alcohol: false, attends_brunch: false, attends_run: false, allergies: nil)
    end

    it "keeps the options independent of one another" do
      expect(build(:family_member, :runner)).to have_attributes(attends_run: true, attends_brunch: false)
    end
  end

  describe "#attends" do
    it "keeps a refusal apart from an unanswered question" do
      expect(create(:family_member, :not_coming).reload.attends).to be(false)
      expect(create(:family_member, :coming).reload.attends).to be(true)
    end
  end

  describe "#valid?" do
    it "requires a family" do
      expect(build(:family_member, family: nil)).not_to be_valid
    end

    context "when no address is given" do
      before { create_list(:family_member, 3) }

      it "accepts any number of members without one" do
        expect(member).to be_valid
      end
    end

    context "when another member already holds the address" do
      subject(:member) { build(:family_member, family: create(:family), email: taken) }

      let(:taken) { "melanie@exemple.fr" }

      before { create(:family_member, email: taken) }

      it "refuses it, whichever families they are in" do
        expect(member).not_to be_valid
        expect(member.errors[:email]).to eq([ I18n.t("errors.attributes.email.taken") ])
      end

      context "in a different case" do
        subject(:member) { build(:family_member, email: taken.upcase) }

        it "still refuses it" do
          expect(member).not_to be_valid
        end
      end
    end

    context "when the member already holds the address itself" do
      subject(:member) { create(:family_member, :with_email) }

      it "does not count its own address as taken" do
        expect(member).to be_valid
      end
    end
  end

  describe "#save" do
    subject(:member) { build(:family_member, email: taken) }

    let(:taken) { "melanie@exemple.fr" }

    before { create(:family_member, email: taken) }

    it "is backed by a unique index, not only the validation" do
      expect { member.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "#adult?" do
    it "is true for an adult alone" do
      expect(member).to be_adult
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
      expect(member).not_to be_child
    end
  end
end
