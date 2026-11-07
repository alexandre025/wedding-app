require "rails_helper"

RSpec.describe "The RSVP link gate" do
  let!(:melanie) { create(:family_member, first_name: "Mélanie", email: "melanie@exemple.fr") }

  describe "GET /rsvp" do
    it "asks for the invitation address" do
      get rsvp_path

      expect(response).to have_http_status(:success)
      assert_select "h1", text: I18n.t("rsvp.links.new.title")
      assert_select "label[for=?]", "link_request_email", text: I18n.t("rsvp.links.new.email_label")
      assert_select "input#link_request_email[type=email]"
    end
  end

  describe "POST /rsvp" do
    subject(:request_link) { post rsvp_path, params: { link_request: { email: } } }

    let(:email) { "melanie@exemple.fr" }

    it "emails the link and says where it went" do
      expect { request_link }.to have_enqueued_mail(RsvpMailer, :link)
      expect(response).to redirect_to(rsvp_path)

      follow_redirect!
      assert_select "[role=status] h2", text: I18n.t("rsvp.links.new.sent_title")
      assert_select "[role=status] span", text: email
    end

    context "with a malformed address" do
      let(:email) { "melanie" }

      it "explains the address is not valid" do
        request_link

        expect(response).to have_http_status(:unprocessable_content)
        assert_select "[role=alert]",
          text: I18n.t("activemodel.errors.models.rsvp/link_request_form.attributes.email.invalid")
      end
    end

    context "with an address missing from the guest list" do
      let(:email) { "inconnu@exemple.fr" }

      it "says it cannot find it" do
        expect { request_link }.not_to have_enqueued_mail

        expect(response).to have_http_status(:unprocessable_content)
        assert_select "[role=alert]",
          text: I18n.t("activemodel.errors.models.rsvp/link_request_form.attributes.email.unknown")
      end
    end
  end
end
