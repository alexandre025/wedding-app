require "rails_helper"

RSpec.describe "The admin families screens" do
  let!(:melchior) { create(:family, name: "Melchior") }
  let!(:melanie) { create(:family_member, family: melchior, first_name: "Mélanie", email: "melanie@exemple.fr") }
  let!(:sylvain) { create(:family_member, family: melchior, first_name: "Sylvain") }
  let!(:roux) { create(:family, name: "Roux") }

  it "asks for credentials on every action" do
    get admin_families_path
    expect(response).to have_http_status(:unauthorized)

    get admin_family_path(melchior)
    expect(response).to have_http_status(:unauthorized)

    post admin_families_path, params: { family: { name: "Nouvelle" } }
    expect(response).to have_http_status(:unauthorized)
  end

  describe "the list" do
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

    it "narrows by a member's email when searched" do
      get admin_families_path(q: { Family::SEARCH_PREDICATE => melanie.email }), headers: admin_headers

      expect(response).to have_http_status(:success)
      assert_select "li", text: /#{Regexp.escape(melchior.name)}/
      assert_select "li", text: /#{Regexp.escape(roux.name)}/, count: 0
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

  describe "the family page" do
    it "lists its members, and says which have no address" do
      get admin_family_path(melchior), headers: admin_headers

      expect(response).to have_http_status(:success)
      assert_select "li", text: /#{Regexp.escape(sylvain.first_name)}/
      assert_select "li", text: /#{Regexp.escape(I18n.t("admin.families.show.no_email"))}/
    end

    it "says so when the family has no members at all" do
      get admin_family_path(roux), headers: admin_headers

      assert_select "p", text: I18n.t("admin.families.show.no_members")
    end
  end

  describe "creating one" do
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

  it "keeps a family's members when it is renamed" do
    patch admin_family_path(melchior), params: { family: { name: "Melchior-Dupont" } }, headers: admin_headers

    expect(response).to redirect_to(admin_family_path(melchior))
    expect(melchior.reload.name).to eq("Melchior-Dupont")
    expect(melchior.family_members.count).to eq(2)
  end

  it "takes the members along when a family is deleted" do
    expect { delete admin_family_path(melchior), headers: admin_headers }
      .to change(Family, :count).by(-1)
      .and change(FamilyMember, :count).by(-2)

    expect(response).to redirect_to(admin_families_path)
  end
end
