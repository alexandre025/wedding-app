require "rails_helper"

RSpec.describe "The public pages" do
  describe "GET /" do
    before { get root_path }

    it "introduces the couple and links to the RSVP gate" do
      expect(response).to have_http_status(:success)
      assert_select "h1 span", text: I18n.t("wedding.partner_one")
      assert_select "h1 span", text: I18n.t("wedding.partner_two")
      assert_select "a[href=?]", rsvp_path
    end
  end

  describe "GET /schedule" do
    before { get schedule_path }

    it "lists every day of the weekend and the practical info" do
      expect(response).to have_http_status(:success)
      assert_select "h1", text: /#{Regexp.escape(I18n.t("pages.schedule.title"))}/

      I18n.t("pages.schedule.days").each do |day|
        assert_select "h2", text: /#{Regexp.escape(day[:label])}/

        day[:items].each do |item|
          assert_select "li", text: /#{Regexp.escape(item[:name])}/
        end
      end

      assert_select "h3", text: /#{Regexp.escape(I18n.t("pages.schedule.info_cards.dress.name"))}/
    end
  end

  describe "GET /rsvp" do
    before { get rsvp_path }

    it "renders the email gate" do
      expect(response).to have_http_status(:success)
      assert_select "h1", text: /#{Regexp.escape(I18n.t("pages.rsvp.title"))}/
      assert_select "label[for=?]", "rsvp-email", text: /#{Regexp.escape(I18n.t("pages.rsvp.email_label"))}/
      assert_select "input#rsvp-email[type=email]"
      assert_select "[data-controller=?]", "email-gate"
    end
  end
end
