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

  describe "the options" do
    it "records every one posted from the form" do
      post admin_family_members_path(roux),
        params: { family_member: { first_name: "Antoine", email: "", attends_run: "1", attends_brunch: "0",
                                   no_alcohol: "1", allergies: "Arachides" } },
        headers: admin_headers

      member = roux.family_members.last
      expect(member.attends_run).to be(true)
      expect(member.attends_brunch).to be(false)
      expect(member.no_alcohol).to be(true)
      expect(member.allergies).to eq("Arachides")
    end

    it "keeps a refusal apart from an unanswered attendance over HTTP" do
      post admin_family_members_path(roux),
        params: { family_member: { first_name: "Antoine", email: "", attends: "false" } },
        headers: admin_headers
      expect(roux.family_members.last.attends).to be(false)

      post admin_family_members_path(roux),
        params: { family_member: { first_name: "Claire", email: "", attends: "" } },
        headers: admin_headers
      expect(roux.family_members.last.attends).to be_nil
    end

    it "selects the stored attendance when the form is reopened" do
      melanie.update!(attends: false)

      get edit_admin_member_path(melanie), headers: admin_headers

      assert_select "select[name=?] option[selected]", "family_member[attends]", count: 1,
        text: I18n.t("admin.family_members.attendance.not_coming")
    end

    it "shows the options for a member who is coming" do
      melanie.update!(attends: true)

      get edit_admin_member_path(melanie), headers: admin_headers

      assert_select "[data-member-options-target=options]"
      assert_select "[data-member-options-target=options][hidden]", count: 0
    end

    it "hides them for a member who is not coming, and for one who has not answered" do
      melanie.update!(attends: false)
      get edit_admin_member_path(melanie), headers: admin_headers
      assert_select "[data-member-options-target=options][hidden]"

      melanie.update!(attends: nil)
      get edit_admin_member_path(melanie), headers: admin_headers
      assert_select "[data-member-options-target=options][hidden]"
    end

    it "keeps the hidden answers rather than dropping them, since hidden fields still submit" do
      melanie.update!(attends: false, attends_run: true, no_alcohol: true, allergies: "Arachides")

      get edit_admin_member_path(melanie), headers: admin_headers
      patch admin_member_path(melanie), params: { family_member: submitted_form_fields(response.body) },
        headers: admin_headers

      expect(melanie.reload).to have_attributes(attends: false, attends_run: true, no_alcohol: true,
        allergies: "Arachides")
    end

    it "ticks the boxes that are stored and leaves the others alone" do
      melanie.update!(attends_run: true, no_alcohol: true)

      get edit_admin_member_path(melanie), headers: admin_headers

      assert_select "input[type=checkbox][name=?][checked]", "family_member[attends_run]"
      assert_select "input[type=checkbox][name=?][checked]", "family_member[no_alcohol]"
      assert_select "input[type=checkbox][name=?][checked]", "family_member[attends_brunch]", count: 0
    end

    it "changes nothing when the edit form is submitted untouched" do
      melanie.update!(attends: false, attends_run: true, attends_brunch: false, no_alcohol: true,
        allergies: "Arachides")

      get edit_admin_member_path(melanie), headers: admin_headers

      patch admin_member_path(melanie), params: { family_member: submitted_form_fields(response.body) },
        headers: admin_headers

      expect(melanie.reload).to have_attributes(first_name: "Mélanie", email: "melanie@exemple.fr",
        age_group: FamilyMember::ADULT, attends: false, attends_run: true, attends_brunch: false,
        no_alcohol: true, allergies: "Arachides")
    end
  end

  it "keeps the member attached to its family when edited" do
    patch admin_member_path(melanie),
      params: { family_member: { first_name: "Mélanie-Claire", email: melanie.email,
                                 age_group: melanie.age_group } },
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
