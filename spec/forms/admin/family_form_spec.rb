require "rails_helper"

RSpec.describe Admin::FamilyForm do
  it "creates the family on a valid submission" do
    form = described_class.new(Family.new)

    expect { form.submit(name: "Melchior") }.to change(Family, :count).by(1)
    expect(Family.last.name).to eq("Melchior")
  end

  it "strips the name before saving it" do
    form = described_class.new(Family.new)
    form.submit(name: "  Melchior  ")

    expect(Family.last.name).to eq("Melchior")
  end

  it "refuses a blank name" do
    form = described_class.new(Family.new)

    expect { form.submit(name: " ") }.not_to change(Family, :count)
    expect(form.errors[:name]).to eq([ I18n.t("errors.attributes.name.blank") ])
  end
end
