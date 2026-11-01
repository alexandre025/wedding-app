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

    it "strips the allergies" do
      form_for_new_member.submit(first_name: "Antoine", email: "", allergies: "  Arachides  ")

      expect(family.family_members.last.allergies).to eq("Arachides")
    end

    it "stores nil for blank allergies" do
      form_for_new_member.submit(first_name: "Antoine", email: "", allergies: "   ")

      expect(family.family_members.last.allergies).to be_nil
    end
  end

  describe "the options" do
    def submit_with(params) = form_for_new_member.submit({ first_name: "Antoine", email: "" }.merge(params))

    it "records a ticked box, an unticked one and a missing one" do
      submit_with(attends_brunch: "1")
      expect(family.family_members.last.attends_brunch).to be(true)

      submit_with(attends_brunch: "0")
      expect(family.family_members.last.attends_brunch).to be(false)

      submit_with({})
      expect(family.family_members.last.attends_brunch).to be(false)
    end

    it "keeps a refusal, a yes and an unanswered attendance apart" do
      submit_with(attends: "true")
      expect(family.family_members.last.attends).to be(true)

      submit_with(attends: "false")
      expect(family.family_members.last.attends).to be(false)

      submit_with(attends: "")
      expect(family.family_members.last.attends).to be_nil
    end

    it "reads every stored option back into the form" do
      member = create(:family_member, :runner, :brunching, :teetotal, :with_allergies, family:)

      form = described_class.new(member)

      expect(form.attends_run).to be(true)
      expect(form.attends_brunch).to be(true)
      expect(form.no_alcohol).to be(true)
      expect(form.allergies).to eq("Arachides")
    end

    it "lets an adult run and drink" do
      submit_with(attends_run: "1", no_alcohol: "0")

      member = family.family_members.last
      expect(member.attends_run).to be(true)
      expect(member.no_alcohol).to be(false)
    end
  end

  describe "the age rules" do
    def submit_with(params) = form_for_new_member.submit({ first_name: "Antoine", email: "" }.merge(params))

    it "keeps a teenager off the alcohol even when the params say otherwise" do
      submit_with(age_group: FamilyMember::TEEN, no_alcohol: "0")

      expect(family.family_members.last.no_alcohol).to be(true)
    end

    it "still lets a teenager run" do
      submit_with(age_group: FamilyMember::TEEN, attends_run: "1")

      expect(family.family_members.last.attends_run).to be(true)
    end

    it "keeps a baby off the run even when the params say otherwise" do
      submit_with(age_group: FamilyMember::BABY, attends_run: "1")

      expect(family.family_members.last.attends_run).to be(false)
    end

    it "applies the rule to the age group being submitted, not the stored one" do
      member = create(:family_member, family:, no_alcohol: false, attends_run: true)

      described_class.new(member).submit(first_name: member.first_name, email: "",
        age_group: FamilyMember::BABY, no_alcohol: "0", attends_run: "1")

      expect(member.reload.no_alcohol).to be(true)
      expect(member.attends_run).to be(false)
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
