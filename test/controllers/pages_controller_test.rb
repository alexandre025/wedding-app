require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "home introduces the couple and links to the RSVP gate" do
    get root_path

    assert_response :success
    assert_select "h1 span", text: I18n.t("wedding.partner_one")
    assert_select "h1 span", text: I18n.t("wedding.partner_two")
    assert_select "a[href=?]", rsvp_path
  end

  test "schedule lists every day of the weekend and the practical info" do
    get schedule_path

    assert_response :success
    assert_select "h1", text: /#{Regexp.escape(I18n.t("pages.schedule.title"))}/

    I18n.t("pages.schedule.days").each do |day|
      assert_select "h2", text: /#{Regexp.escape(day[:label])}/
      day[:items].each do |item|
        assert_select "li", text: /#{Regexp.escape(item[:name])}/
      end
    end

    assert_select "h3", text: /#{Regexp.escape(I18n.t("pages.schedule.info_cards.dress.name"))}/
  end

  test "rsvp renders the email gate" do
    get rsvp_path

    assert_response :success
    assert_select "h1", text: /#{Regexp.escape(I18n.t("pages.rsvp.title"))}/
    assert_select "label[for=?]", "rsvp-email", text: /#{Regexp.escape(I18n.t("pages.rsvp.email_label"))}/
    assert_select "input#rsvp-email[type=email]"
    assert_select "[data-controller=?]", "email-gate"
  end
end
