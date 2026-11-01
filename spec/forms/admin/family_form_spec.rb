require "rails_helper"

RSpec.describe Admin::FamilyForm do
  subject(:form) { described_class.new(Family.new) }

  describe "#submit" do
    let(:params) { { name: "Melchior" } }

    it "creates the family on a valid submission" do
      expect { form.submit(params) }.to change(Family, :count).by(1)
      expect(Family.last.name).to eq("Melchior")
    end

    context "when the name is padded" do
      let(:params) { super().merge(name: "  Melchior  ") }

      it "strips it before saving" do
        form.submit(params)

        expect(Family.last.name).to eq("Melchior")
      end
    end

    context "when the name is blank" do
      let(:params) { super().merge(name: " ") }

      it "refuses it" do
        expect { form.submit(params) }.not_to change(Family, :count)
        expect(form.errors[:name]).to eq([ I18n.t("errors.attributes.name.blank") ])
      end
    end
  end
end
