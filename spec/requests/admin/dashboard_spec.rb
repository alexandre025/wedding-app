require "rails_helper"

RSpec.describe "The admin dashboard" do
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
end
