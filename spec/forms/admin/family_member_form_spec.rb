require "rails_helper"

RSpec.describe Admin::FamilyMemberForm do
  let(:family) { create(:family) }

  def form_for_new_member = described_class.new(family.family_members.build)

  it "creates the member on a valid submission" do
    form = form_for_new_member

    expect { form.submit(first_name: "Antoine", email: "antoine@exemple.fr") }
      .to change(FamilyMember, :count).by(1)
  end

  describe "normalizing" do
    it "strips the first name" do
      form_for_new_member.submit(first_name: "  Antoine  ", email: "")

      expect(family.family_members.last.first_name).to eq("Antoine")
    end

    it "strips and lowercases the email" do
      form_for_new_member.submit(first_name: "Antoine", email: "  Antoine.ROUX@Exemple.FR ")

      expect(family.family_members.last.email).to eq("antoine.roux@exemple.fr")
    end

    it "stores nil for a blank email, so another member may also have none" do
      form_for_new_member.submit(first_name: "Antoine", email: "   ")

      expect(family.family_members.last.email).to be_nil
      expect(form_for_new_member.submit(first_name: "Claire", email: "")).to be(true)
    end
  end

  describe "validating" do
    it "refuses a blank first name" do
      form = form_for_new_member

      expect { form.submit(first_name: " ", email: "antoine@exemple.fr") }.not_to change(FamilyMember, :count)
      expect(form.errors[:first_name]).to eq([ I18n.t("errors.attributes.first_name.blank") ])
    end

    it "refuses a malformed email" do
      form = form_for_new_member

      expect { form.submit(first_name: "Antoine", email: "pas-une-adresse") }.not_to change(FamilyMember, :count)
      expect(form.errors[:email]).to eq([ I18n.t("errors.attributes.email.invalid") ])
    end

    it "refuses an address another member already holds" do
      create(:family_member, email: "melanie@exemple.fr")
      form = form_for_new_member

      expect { form.submit(first_name: "Antoine", email: "MELANIE@exemple.fr") }.not_to change(FamilyMember, :count)
      expect(form.errors[:email]).to eq([ I18n.t("errors.attributes.email.taken") ])
    end

    it "does not count a member's own address as taken" do
      member = create(:family_member, :with_email, family: family)

      expect(described_class.new(member).submit(first_name: member.first_name, email: member.email)).to be(true)
    end
  end
end
