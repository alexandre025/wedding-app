require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "the dashboard asks for credentials" do
    get admin_root_path

    assert_response :unauthorized
  end

  test "the wrong credentials are refused" do
    encoded = ActionController::HttpAuthentication::Basic.encode_credentials("admin", "pas-le-bon")

    get admin_root_path, headers: { "HTTP_AUTHORIZATION" => encoded }

    assert_response :unauthorized
  end

  test "the dashboard heads the response tally and names the deadline" do
    get admin_root_path, headers: admin_headers

    assert_response :success
    assert_select "h1", text: I18n.t("admin.dashboard.show.title")
    assert_select "p", text: /#{Regexp.escape(I18n.l(Wedding::RSVP_DEADLINE.to_date, format: :long))}/
  end

  test "the dashboard wears the admin chrome, not the public site's" do
    get admin_root_path, headers: admin_headers

    assert_response :success
    assert_select "nav[aria-label=?]", I18n.t("admin.nav.label")
    assert_select "a[href=?]", root_path, text: I18n.t("admin.view_site")
    assert_select "[aria-label=?]", I18n.t("nav.label"), count: 0
  end
end
