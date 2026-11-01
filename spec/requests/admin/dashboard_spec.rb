require "rails_helper"

RSpec.describe "The admin dashboard" do
  describe "GET /admin" do
    it "asks for credentials" do
      get admin_root_path

      expect(response).to have_http_status(:unauthorized)
    end

    it "refuses the wrong credentials" do
      get admin_root_path, headers: basic_auth_headers("admin", "pas-le-bon")

      expect(response).to have_http_status(:unauthorized)
    end

    it "heads the response tally and names the deadline" do
      get admin_root_path, headers: admin_headers

      expect(response).to have_http_status(:success)
      assert_select "h1", text: I18n.t("admin.dashboard.show.title")
      assert_select "p", text: /#{Regexp.escape(I18n.l(Wedding::RSVP_DEADLINE.to_date, format: :long))}/
    end

    it "wears the admin chrome, not the public site's" do
      get admin_root_path, headers: admin_headers

      assert_select "nav[aria-label=?]", I18n.t("admin.nav.label")
      assert_select "a[href=?]", root_path, text: I18n.t("admin.view_site")
      assert_select "[aria-label=?]", I18n.t("nav.label"), count: 0
    end

    context "with a family that has answered and one that has not" do
      let!(:melchior) { create(:family, name: "Melchior") }
      let!(:roux) { create(:family, name: "Roux") }

      let!(:melanie) do
        create(:family_member, :coming, :runner, :with_allergies, family: melchior, first_name: "Mélanie")
      end

      let!(:sylvain) { create(:family_member, :not_coming, family: melchior, first_name: "Sylvain") }
      let!(:antoine) { create(:family_member, **antoine_attributes) }

      let(:antoine_attributes) { { family: roux, first_name: "Antoine", email: "antoine@exemple.fr" } }

      before { get admin_root_path, headers: admin_headers }

      it "counts the guests into the three states" do
        assert_select "h2", text: I18n.t("admin.dashboard.show.progress_title", count: 3)

        expect(captioned_figures(response.body)).to include(
          I18n.t("admin.dashboard.show.present") => "1",
          I18n.t("admin.dashboard.show.absent") => "1",
          I18n.t("admin.dashboard.show.pending") => "1",
          I18n.t("admin.dashboard.show.families_answered") =>
            I18n.t("admin.dashboard.show.families_ratio", answered: 1, total: 2)
        )
      end

      it "describes the bar for anyone who cannot see it" do
        assert_select "[role=img][aria-label=?]",
          I18n.t("admin.dashboard.show.bar_label", present: 1, absent: 1, pending: 1, total: 3)
      end

      it "counts the Sunday options against the guests who are coming" do
        expect(captioned_figures(response.body)).to include(
          I18n.t("admin.dashboard.show.options.run") => "1 #{I18n.t("admin.dashboard.show.options_of", of: 1)}",
          I18n.t("admin.dashboard.show.options.brunch") => "0 #{I18n.t("admin.dashboard.show.options_of", of: 1)}"
        )
      end

      it "counts the allergies without naming anyone" do
        assert_select "li", text: /#{Regexp.escape(I18n.t("admin.dashboard.show.diets.allergies"))}\s+1/
        assert_select "li", text: /Arachides/, count: 0
      end

      it "offers to chase the family that has not answered" do
        assert_select "li", text: /#{Regexp.escape(I18n.t("admin.families.family_name", name: roux.name))}/

        assert_select "a[aria-label=?]", I18n.t("admin.dashboard.show.remind_label", name: roux.name) do |links|
          expect(links.first["href"]).to start_with("mailto:#{antoine.email}?")
        end
      end

      it "lists what the family that answered said" do
        assert_select "li", text: /#{Regexp.escape(I18n.t("admin.dashboard.show.present_prefix"))}/
        assert_select "li", text: /Mélanie/
        assert_select "li", text: /Sylvain/
      end

      context "when the pending family has no address at all" do
        let(:antoine_attributes) { super().merge(email: nil) }

        it "says so rather than offering a link to nowhere" do
          assert_select "a[aria-label=?]", I18n.t("admin.dashboard.show.remind_label", name: roux.name), count: 0
          assert_select "span", text: I18n.t("admin.families.show.no_email")
        end
      end
    end

    context "with no families at all" do
      before { get admin_root_path, headers: admin_headers }

      it "says both lists are empty rather than rendering nothing" do
        assert_select "p", text: I18n.t("admin.dashboard.show.none_pending")
        assert_select "p", text: I18n.t("admin.dashboard.show.none_recent")
      end
    end
  end
end
