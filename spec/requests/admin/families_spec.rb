require "rails_helper"

RSpec.describe "The admin families screens" do
  let!(:melchior) { create(:family, name: "Melchior") }
  let!(:melanie) { create(:family_member, **melanie_attributes) }
  let!(:sylvain) { create(:family_member, **sylvain_attributes) }
  let!(:roux) { create(:family, name: "Roux") }

  let(:melanie_attributes) { { family: melchior, first_name: "Mélanie", email: "melanie@exemple.fr" } }
  let(:sylvain_attributes) { { family: melchior, first_name: "Sylvain" } }

  it "asks for credentials on every action" do
    get admin_families_path
    expect(response).to have_http_status(:unauthorized)

    get admin_family_path(melchior)
    expect(response).to have_http_status(:unauthorized)

    post admin_families_path, params: { family: { name: "Nouvelle" } }
    expect(response).to have_http_status(:unauthorized)
  end

  describe "GET /admin/families" do
    it "names every family and its members" do
      get admin_families_path, headers: admin_headers

      expect(response).to have_http_status(:success)
      assert_select "h1", text: I18n.t("admin.families.index.title")
      assert_select "li", text: /#{Regexp.escape(melchior.name)}/
      assert_select "li", text: /#{Regexp.escape(melanie.email)}/
    end

    it "says so when a family has no members" do
      get admin_families_path, headers: admin_headers

      assert_select "li", text: /#{Regexp.escape(I18n.t("admin.families.no_members"))}/
    end

    it "counts no family as answered while one of its members has not" do
      get admin_families_path, headers: admin_headers

      expect(captioned_figures(response.body)).to include(
        I18n.t("admin.families.index.stats.answered") =>
          I18n.t("admin.families.index.stats.ratio", answered: 0, total: 2)
      )
    end

    context "when every member of a family has answered" do
      let(:melanie_attributes) { super().merge(attends: true) }
      let(:sylvain_attributes) { super().merge(attends: false) }

      it "counts it, refusals included" do
        get admin_families_path, headers: admin_headers

        expect(captioned_figures(response.body)).to include(
          I18n.t("admin.families.index.stats.answered") =>
            I18n.t("admin.families.index.stats.ratio", answered: 1, total: 2)
        )
      end
    end

    it "narrows by a member's email when searched" do
      get admin_families_path(q: { Family::SEARCH_PREDICATE => melanie.email }), headers: admin_headers

      expect(response).to have_http_status(:success)
      assert_select "li", text: /#{Regexp.escape(melchior.name)}/
      assert_select "li", text: /#{Regexp.escape(roux.name)}/, count: 0
    end

    it "wires the search box up for auto-submit and clearing" do
      get admin_families_path, headers: admin_headers

      assert_select "form[data-controller=?]", "search-field"
      assert_select "form[data-turbo-frame=?]", "families_results"
      assert_select "input[data-search-field-target=?]", "field"
      assert_select "button[data-search-field-target=?]", "clear" do |buttons|
        expect(buttons.first["aria-label"]).to eq(I18n.t("admin.families.index.search_clear"))
        expect(buttons.first["hidden"]).not_to be_nil
      end
    end

    it "puts the results in a frame the search can replace on its own" do
      get admin_families_path, headers: admin_headers

      assert_select "turbo-frame#families_results li", text: /#{Regexp.escape(melchior.name)}/
    end

    it "lets the row controls leave the frame rather than navigate inside it" do
      get admin_families_path, headers: admin_headers

      assert_select "turbo-frame#families_results[target=?]", "_top"
      assert_select "turbo-frame#families_results a[href=?]", admin_family_path(melchior)
    end

    it "names the term that found nothing" do
      get admin_families_path(q: { Family::SEARCH_PREDICATE => "introuvable" }), headers: admin_headers

      assert_select "p", text: I18n.t("admin.families.index.none_matching", query: "introuvable")
    end

    it "survives a stale URL that passes q as a bare string" do
      get admin_families_path(q: "introuvable"), headers: admin_headers

      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/families/:id" do
    it "lists its members, and says which have no address" do
      get admin_family_path(melchior), headers: admin_headers

      expect(response).to have_http_status(:success)
      assert_select "li", text: /#{Regexp.escape(sylvain.first_name)}/
      assert_select "li", text: /#{Regexp.escape(I18n.t("admin.families.show.no_email"))}/
    end

    context "when a member is a teenager" do
      let(:sylvain_attributes) { super().merge(age_group: FamilyMember::TEEN) }

      it "shows the age group" do
        get admin_family_path(melchior), headers: admin_headers

        assert_select "li", text: /#{Regexp.escape(I18n.t("admin.family_members.age_groups.teen"))}/
      end
    end

    context "when one member is coming and another is not" do
      let(:melanie_attributes) { super().merge(attends: true) }
      let(:sylvain_attributes) { super().merge(attends: false) }

      it "badges each of them" do
        get admin_family_path(melchior), headers: admin_headers

        assert_select "li", text: /#{Regexp.escape(I18n.t("admin.family_members.attendance.coming"))}/
        assert_select "li", text: /#{Regexp.escape(I18n.t("admin.family_members.attendance.not_coming"))}/
      end
    end

    it "badges nothing for a member who has not answered" do
      get admin_family_path(melchior), headers: admin_headers

      assert_select "li", text: /#{Regexp.escape(I18n.t("admin.family_members.attendance.coming"))}/, count: 0
      assert_select "li", text: /#{Regexp.escape(I18n.t("admin.family_members.attendance.unanswered"))}/, count: 0
    end

    context "when a member runs and brunches" do
      let(:sylvain_attributes) { super().merge(attends_run: true, attends_brunch: true) }

      it "tags those, and only those" do
        get admin_family_path(melchior), headers: admin_headers

        assert_select "li", text: /#{Regexp.escape(I18n.t("admin.family_members.tags.run"))}/
        assert_select "li", text: /#{Regexp.escape(I18n.t("admin.family_members.tags.brunch"))}/
        assert_select "li", text: /#{Regexp.escape(I18n.t("admin.family_members.tags.no_alcohol"))}/, count: 0
      end
    end

    context "when an adult does not drink" do
      let(:sylvain_attributes) { super().merge(no_alcohol: true) }

      it "tags them" do
        get admin_family_path(melchior), headers: admin_headers

        assert_select "li", text: /#{Regexp.escape(I18n.t("admin.family_members.tags.no_alcohol"))}/
      end
    end

    context "when a child does not drink" do
      let(:sylvain_attributes) { super().merge(age_group: FamilyMember::KID, no_alcohol: true) }

      it "leaves the tag off, since the rule decided it" do
        get admin_family_path(melchior), headers: admin_headers

        assert_select "li", text: /#{Regexp.escape(I18n.t("admin.family_members.tags.no_alcohol"))}/, count: 0
      end
    end

    context "when a member has allergies" do
      let(:sylvain_attributes) { super().merge(allergies: "Arachides et fruits à coque") }

      it "shows them" do
        get admin_family_path(melchior), headers: admin_headers

        assert_select "li", text: /Arachides et fruits à coque/
      end
    end

    it "says so when the family has no members at all" do
      get admin_family_path(roux), headers: admin_headers

      assert_select "p", text: I18n.t("admin.families.show.no_members")
    end
  end

  describe "POST /admin/families" do
    it "sends you on to add its first member" do
      expect { post admin_families_path, params: { family: { name: "Nouvelle" } }, headers: admin_headers }
        .to change(Family, :count).by(1)

      expect(response).to redirect_to(new_admin_family_member_path(Family.find_by(name: "Nouvelle")))
    end

    it "re-renders with its error when the name is blank" do
      expect { post admin_families_path, params: { family: { name: " " } }, headers: admin_headers }
        .not_to change(Family, :count)

      expect(response).to have_http_status(:unprocessable_content)
      assert_select "[role=alert]", text: /#{Regexp.escape(I18n.t("errors.attributes.name.blank"))}/
    end
  end

  describe "PATCH /admin/families/:id" do
    it "keeps a family's members when it is renamed" do
      patch admin_family_path(melchior), params: { family: { name: "Melchior-Dupont" } }, headers: admin_headers

      expect(response).to redirect_to(admin_family_path(melchior))
      expect(melchior.reload.name).to eq("Melchior-Dupont")
      expect(melchior.family_members.count).to eq(2)
    end
  end

  describe "DELETE /admin/families/:id" do
    it "takes the members along when a family is deleted" do
      expect { delete admin_family_path(melchior), headers: admin_headers }
        .to change(Family, :count).by(-1)
        .and change(FamilyMember, :count).by(-2)

      expect(response).to redirect_to(admin_families_path)
    end
  end
end
