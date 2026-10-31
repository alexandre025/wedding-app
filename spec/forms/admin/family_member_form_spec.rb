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

    it "accepts every age group the model lists" do
      FamilyMember::AGE_GROUPS.each do |group|
        form = described_class.new(family.family_members.build)

        expect(form.submit(first_name: "Antoine", email: "", age_group: group)).to be(true)
        expect(family.family_members.last.age_group).to eq(group)
      end
    end

    it "refuses an age group outside the list" do
      form = form_for_new_member

      expect { form.submit(first_name: "Antoine", email: "", age_group: "vieux") }
        .not_to change(FamilyMember, :count)
      expect(form.errors[:age_group]).to eq([ I18n.t("errors.attributes.age_group.inclusion") ])
    end

    it "refuses a malformed email" do
      form = form_for_new_member

      expect { form.submit(first_name: "Antoine", email: "pas-une-adresse") }.not_to change(FamilyMember, :count)
      expect(form.errors[:email]).to eq([ I18n.t("errors.attributes.email.invalid") ])
    end

    it "surfaces the model's duplicate-address error rather than raising" do
      create(:family_member, family: create(:family), email: "melanie@exemple.fr")
      form = form_for_new_member

      expect { form.submit(first_name: "Antoine", email: "MELANIE@exemple.fr") }.not_to change(FamilyMember, :count)
      expect(form.errors[:email]).to eq([ I18n.t("errors.attributes.email.taken") ])
    end
  end
end
