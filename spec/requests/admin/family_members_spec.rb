require "rails_helper"

RSpec.describe "The admin family member screens" do
  let!(:melchior) { create(:family, name: "Melchior") }
  let!(:roux) { create(:family, name: "Roux") }
  let!(:melanie) { create(:family_member, **member_attributes) }

  let(:member_attributes) { { family: melchior, first_name: "Mélanie", email: "melanie@exemple.fr" } }

  it "asks for credentials on every action" do
    get new_admin_family_member_path(roux)
    expect(response).to have_http_status(:unauthorized)

    get edit_admin_member_path(melanie)
    expect(response).to have_http_status(:unauthorized)

    delete admin_member_path(melanie)
    expect(response).to have_http_status(:unauthorized)
  end

  describe "POST /admin/families/:family_id/members" do
    subject(:create_member) do
      post admin_family_members_path(roux), params: { family_member: params }, headers: admin_headers
    end

    let(:params) { { first_name: "Antoine", email: "antoine@exemple.fr" } }

    it "returns to the family" do
      expect { create_member }.to change { roux.family_members.count }.by(1)
      expect(response).to redirect_to(admin_family_path(roux))
    end

    context "with no email" do
      let(:params) { super().merge(email: "") }

      it "accepts the member" do
        create_member

        expect(roux.family_members.last.email).to be_nil
      end
    end

    context "with every option answered" do
      let(:params) do
        super().merge(email: "", attends_run: "1", attends_brunch: "0", no_alcohol: "1", vegetarian: "1",
          allergies: "Arachides")
      end

      it "records every one of them" do
        create_member

        expect(roux.family_members.last).to have_attributes(attends_run: true, attends_brunch: false,
          no_alcohol: true, vegetarian: true, allergies: "Arachides")
      end
    end

    context "with attendance refused" do
      let(:params) { super().merge(email: "", attends: "false") }

      it "keeps the refusal apart from an unanswered question" do
        create_member

        expect(roux.family_members.last.attends).to be(false)
      end
    end

    context "with attendance left unanswered" do
      let(:params) { super().merge(email: "", attends: "") }

      it "stores nil" do
        create_member

        expect(roux.family_members.last.attends).to be_nil
      end
    end

    context "with an address another family already holds" do
      let(:params) { super().merge(email: melanie.email) }

      it "re-renders with the error" do
        expect { create_member }.not_to change(FamilyMember, :count)

        expect(response).to have_http_status(:unprocessable_content)
        assert_select "[role=alert]", text: /#{Regexp.escape(I18n.t("errors.attributes.email.taken"))}/
      end
    end

    context "with a blank first name" do
      let(:params) { super().merge(first_name: " ", email: "") }

      it "re-renders with the error" do
        expect { create_member }.not_to change(FamilyMember, :count)

        expect(response).to have_http_status(:unprocessable_content)
        assert_select "[role=alert]", text: /#{Regexp.escape(I18n.t("errors.attributes.first_name.blank"))}/
      end
    end
  end

  describe "GET /admin/members/:id/edit" do
    before { get edit_admin_member_path(melanie), headers: admin_headers }

    context "for a member who is coming" do
      let(:member_attributes) { super().merge(attends: true) }

      it "shows the options" do
        assert_select "[data-member-options-target=options]"
        assert_select "[data-member-options-target=options][hidden]", count: 0
      end
    end

    context "for a member who is not coming" do
      let(:member_attributes) { super().merge(attends: false) }

      it "hides the options" do
        assert_select "[data-member-options-target=options][hidden]"
      end

      it "selects the stored attendance" do
        assert_select "select[name=?] option[selected]", "family_member[attends]", count: 1,
          text: I18n.t("admin.family_members.attendance.not_coming")
      end
    end

    context "for a member who has not answered" do
      it "hides the options" do
        assert_select "[data-member-options-target=options][hidden]"
      end
    end

    context "for a member with options stored" do
      let(:member_attributes) { super().merge(attends_run: true, no_alcohol: true, vegetarian: true) }

      it "ticks the boxes that are stored and leaves the others alone" do
        assert_select "input[type=checkbox][name=?][checked]", "family_member[attends_run]"
        assert_select "input[type=checkbox][name=?][checked]", "family_member[no_alcohol]"
        assert_select "input[type=checkbox][name=?][checked]", "family_member[vegetarian]"
        assert_select "input[type=checkbox][name=?][checked]", "family_member[attends_brunch]", count: 0
      end
    end
  end

  describe "PATCH /admin/members/:id" do
    it "keeps the member attached to its family" do
      patch admin_member_path(melanie),
        params: { family_member: { first_name: "Mélanie-Claire", email: melanie.email,
                                   age_group: melanie.age_group } },
        headers: admin_headers

      expect(response).to redirect_to(admin_family_path(melchior))
      expect(melanie.reload.first_name).to eq("Mélanie-Claire")
      expect(melanie.family).to eq(melchior)
    end

    context "when the edit form is submitted back untouched" do
      let(:member_attributes) do
        super().merge(attends: false, attends_run: true, attends_brunch: false, no_alcohol: true,
          allergies: "Arachides")
      end

      before { get edit_admin_member_path(melanie), headers: admin_headers }

      it "changes nothing, hidden options included" do
        patch admin_member_path(melanie), params: { family_member: submitted_form_fields(response.body) },
          headers: admin_headers

        expect(melanie.reload).to have_attributes(first_name: "Mélanie", email: "melanie@exemple.fr",
          age_group: FamilyMember::ADULT, attends: false, attends_run: true, attends_brunch: false,
          no_alcohol: true, allergies: "Arachides")
      end
    end
  end

  describe "DELETE /admin/members/:id" do
    it "leaves the family standing" do
      expect { delete admin_member_path(melanie), headers: admin_headers }
        .to change(FamilyMember, :count).by(-1)

      expect(response).to redirect_to(admin_family_path(melchior))
      expect(Family.exists?(melchior.id)).to be(true)
    end
  end
end
