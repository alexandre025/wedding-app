require "rails_helper"

RSpec.describe "The admin family member screens" do
  let!(:melchior) { create(:family, name: "Melchior") }
  let!(:melanie) { create(:family_member, family: melchior, first_name: "Mélanie", email: "melanie@exemple.fr") }
  let!(:roux) { create(:family, name: "Roux") }

  it "asks for credentials on every action" do
    get new_admin_family_member_path(roux)
    expect(response).to have_http_status(:unauthorized)

    get edit_admin_member_path(melanie)
    expect(response).to have_http_status(:unauthorized)

    delete admin_member_path(melanie)
    expect(response).to have_http_status(:unauthorized)
  end

  describe "adding one" do
    it "returns to the family" do
      expect {
        post admin_family_members_path(roux),
          params: { family_member: { first_name: "Antoine", email: "antoine@exemple.fr" } },
          headers: admin_headers
      }.to change { roux.family_members.count }.by(1)

      expect(response).to redirect_to(admin_family_path(roux))
    end

    it "accepts a member with no email" do
      post admin_family_members_path(roux),
        params: { family_member: { first_name: "Antoine", email: "" } },
        headers: admin_headers

      expect(roux.family_members.last.email).to be_nil
    end

    it "refuses an address already used by another family" do
      expect {
        post admin_family_members_path(roux),
          params: { family_member: { first_name: "Antoine", email: melanie.email } },
          headers: admin_headers
      }.not_to change(FamilyMember, :count)

      expect(response).to have_http_status(:unprocessable_content)
      assert_select "[role=alert]", text: /#{Regexp.escape(I18n.t("errors.attributes.email.taken"))}/
    end

    it "re-renders with its error when the first name is blank" do
      expect {
        post admin_family_members_path(roux),
          params: { family_member: { first_name: " ", email: "" } },
          headers: admin_headers
      }.not_to change(FamilyMember, :count)

      expect(response).to have_http_status(:unprocessable_content)
      assert_select "[role=alert]", text: /#{Regexp.escape(I18n.t("errors.attributes.first_name.blank"))}/
    end
  end

  it "keeps the member attached to its family when edited" do
    patch admin_member_path(melanie),
      params: { family_member: { first_name: "Mélanie-Claire", email: melanie.email } },
      headers: admin_headers

    expect(response).to redirect_to(admin_family_path(melchior))
    expect(melanie.reload.first_name).to eq("Mélanie-Claire")
    expect(melanie.family).to eq(melchior)
  end

  it "leaves the family standing when a member is removed" do
    expect { delete admin_member_path(melanie), headers: admin_headers }
      .to change(FamilyMember, :count).by(-1)

    expect(response).to redirect_to(admin_family_path(melchior))
    expect(Family.exists?(melchior.id)).to be(true)
  end
end
