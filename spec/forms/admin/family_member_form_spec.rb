require "rails_helper"

RSpec.describe Admin::FamilyMemberForm do
  subject(:form) { described_class.new(family.family_members.build) }

  let(:family) { create(:family) }
  let(:member) { family.family_members.last }
  let(:params) { { first_name: "Antoine", email: "" } }

  describe ".new" do
    subject(:form) { described_class.new(stored) }

    let(:stored) { create(:family_member, :runner, :brunching, :teetotal, :with_allergies, :coming, family:) }

    it "reads every stored answer back into the form" do
      expect(form).to have_attributes(attends: true, attends_run: true, attends_brunch: true,
        no_alcohol: true, allergies: "Arachides")
    end
  end

  describe "#submit" do
    it "creates the member on a valid submission" do
      expect { form.submit(params.merge(email: "antoine@exemple.fr")) }.to change(FamilyMember, :count).by(1)
    end

    context "when the first name is padded" do
      let(:params) { super().merge(first_name: "  Antoine  ") }

      it "strips it" do
        form.submit(params)

        expect(member.first_name).to eq("Antoine")
      end
    end

    context "when the email is padded and capitalised" do
      let(:params) { super().merge(email: "  Antoine.ROUX@Exemple.FR ") }

      it "strips and lowercases it" do
        form.submit(params)

        expect(member.email).to eq("antoine.roux@exemple.fr")
      end
    end

    context "when the email is blank" do
      let(:params) { super().merge(email: "   ") }

      it "stores nil, so another member may also have none" do
        form.submit(params)

        expect(member.email).to be_nil
        expect(described_class.new(family.family_members.build).submit(first_name: "Claire", email: "")).to be(true)
      end
    end

    context "when the allergies are padded" do
      let(:params) { super().merge(allergies: "  Arachides  ") }

      it "strips them" do
        form.submit(params)

        expect(member.allergies).to eq("Arachides")
      end
    end

    context "when the allergies are blank" do
      let(:params) { super().merge(allergies: "   ") }

      it "stores nil" do
        form.submit(params)

        expect(member.allergies).to be_nil
      end
    end

    context "when a box is ticked" do
      let(:params) { super().merge(attends_brunch: "1") }

      it "records it" do
        form.submit(params)

        expect(member.attends_brunch).to be(true)
      end
    end

    context "when a box is unticked" do
      let(:params) { super().merge(attends_brunch: "0") }

      it "records the refusal" do
        form.submit(params)

        expect(member.attends_brunch).to be(false)
      end
    end

    context "when a box is missing from the submission" do
      it "falls back to its default" do
        form.submit(params)

        expect(member.attends_brunch).to be(false)
      end
    end

    context "when attendance is answered" do
      let(:params) { super().merge(attends: "true") }

      it "records the yes" do
        form.submit(params)

        expect(member.attends).to be(true)
      end
    end

    context "when attendance is refused" do
      let(:params) { super().merge(attends: "false") }

      it "keeps the refusal apart from an unanswered question" do
        form.submit(params)

        expect(member.attends).to be(false)
      end
    end

    context "when attendance is left unanswered" do
      let(:params) { super().merge(attends: "") }

      it "stores nil" do
        form.submit(params)

        expect(member.attends).to be_nil
      end
    end

    context "when the member is an adult" do
      let(:params) { super().merge(age_group: FamilyMember::ADULT, attends_run: "1", no_alcohol: "0") }

      it "lets them run and drink" do
        form.submit(params)

        expect(member).to have_attributes(attends_run: true, no_alcohol: false)
      end
    end

    context "when the member is a teenager" do
      let(:params) { super().merge(age_group: FamilyMember::TEEN, no_alcohol: "0", attends_run: "1") }

      it "keeps them off the alcohol whatever the params say" do
        form.submit(params)

        expect(member.no_alcohol).to be(true)
      end

      it "still lets them run" do
        form.submit(params)

        expect(member.attends_run).to be(true)
      end
    end

    context "when the member is a baby" do
      let(:params) { super().merge(age_group: FamilyMember::BABY, attends_run: "1") }

      it "keeps them off the run whatever the params say" do
        form.submit(params)

        expect(member.attends_run).to be(false)
      end
    end

    context "when an adult is demoted in the same submission" do
      subject(:form) { described_class.new(stored) }

      let(:stored) { create(:family_member, family:, no_alcohol: false, attends_run: true) }
      let(:params) do
        { first_name: stored.first_name, email: "", age_group: FamilyMember::BABY,
          no_alcohol: "0", attends_run: "1" }
      end

      it "applies the rule to the age group being submitted, not the stored one" do
        form.submit(params)

        expect(stored.reload).to have_attributes(no_alcohol: true, attends_run: false)
      end
    end

    context "when the first name is blank" do
      let(:params) { super().merge(first_name: " ", email: "antoine@exemple.fr") }

      it "refuses it" do
        expect { form.submit(params) }.not_to change(FamilyMember, :count)
        expect(form.errors[:first_name]).to eq([ I18n.t("errors.attributes.first_name.blank") ])
      end
    end

    context "when the age group is outside the list" do
      let(:params) { super().merge(age_group: "vieux") }

      it "refuses it" do
        expect { form.submit(params) }.not_to change(FamilyMember, :count)
        expect(form.errors[:age_group]).to eq([ I18n.t("errors.attributes.age_group.inclusion") ])
      end
    end

    context "when the email is malformed" do
      let(:params) { super().merge(email: "pas-une-adresse") }

      it "refuses it" do
        expect { form.submit(params) }.not_to change(FamilyMember, :count)
        expect(form.errors[:email]).to eq([ I18n.t("errors.attributes.email.invalid") ])
      end
    end

    context "when another member already holds the address" do
      let(:params) { super().merge(email: "MELANIE@exemple.fr") }

      before { create(:family_member, family: create(:family), email: "melanie@exemple.fr") }

      it "surfaces the model's error rather than raising" do
        expect { form.submit(params) }.not_to change(FamilyMember, :count)
        expect(form.errors[:email]).to eq([ I18n.t("errors.attributes.email.taken") ])
      end
    end

    context "when every age group in the list is submitted" do
      it "accepts each one" do
        FamilyMember::AGE_GROUPS.each do |group|
          fresh = described_class.new(family.family_members.build)

          expect(fresh.submit(params.merge(age_group: group))).to be(true)
          expect(family.family_members.last.age_group).to eq(group)
        end
      end
    end
  end
end
