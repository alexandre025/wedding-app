require "rails_helper"

RSpec.describe "The guest RSVP form" do
  let(:family) { create(:family, name: "Melchior") }
  let!(:melanie) { create(:family_member, family:, first_name: "Mélanie") }
  let!(:lena) { create(:family_member, :kid, family:, first_name: "Léna") }
  let(:token) { family.signed_id(purpose: :rsvp) }

  shared_examples "a rejected link" do
    it "sends the guest back to the gate" do
      expect(response).to redirect_to(rsvp_path)
      expect(flash[:alert]).to eq(I18n.t("rsvp.answers.invalid_link"))
    end
  end

  describe "GET /rsvp/:token/edit" do
    before { get edit_rsvp_answer_path(token) }

    it "lists every member of the family" do
      expect(response).to have_http_status(:success)
      assert_select "h1", text: I18n.t("rsvp.answers.family_name", name: "Melchior")
      assert_select "[role=group] > span", text: "Mélanie"
      assert_select "[role=group] > span", text: "Léna"
    end

    it "offers the run to the adult only" do
      assert_select "input[name=?]", "answer[members][#{melanie.id}][attends_run]"
      assert_select "input[name=?]", "answer[members][#{lena.id}][attends_run]", count: 0
    end

    context "with a tampered token" do
      let(:token) { "#{family.signed_id(purpose: :rsvp)}x" }

      it_behaves_like "a rejected link"
    end

    context "with a token for a family since removed" do
      let(:token) { family.signed_id(purpose: :rsvp).tap { family.destroy } }

      it_behaves_like "a rejected link"
    end
  end

  describe "PATCH /rsvp/:token" do
    subject(:answer) { patch rsvp_answer_path(token), params: { answer: params } }

    let(:params) do
      {
        members: {
          melanie.id.to_s => { attends: "true", attends_brunch: "1" },
          lena.id.to_s => { attends: "false" }
        },
        song: "Les Champs-Élysées"
      }
    end

    it "records the answer and shows the confirmation" do
      answer

      expect(response).to redirect_to(rsvp_answer_path(token))
      expect(melanie.reload).to have_attributes(attends: true, attends_brunch: true)
      expect(family.reload.song).to eq("Les Champs-Élysées")
    end

    context "with a member left unanswered" do
      let(:params) { super().merge(members: { melanie.id.to_s => { attends: "true" } }) }

      it "asks for every member" do
        answer

        expect(response).to have_http_status(:unprocessable_content)
        assert_select "[role=alert]",
          text: I18n.t("activemodel.errors.models.rsvp/answer_form.attributes.base.unanswered")
      end
    end
  end

  describe "GET /rsvp/:token" do
    before { get rsvp_answer_path(token) }

    it "sends an unanswered family to the form" do
      expect(response).to redirect_to(edit_rsvp_answer_path(token))
    end

    context "when the family is coming" do
      let!(:melanie) { create(:family_member, :coming, :brunching, family:, first_name: "Mélanie") }
      let!(:lena) { create(:family_member, :kid, :not_coming, family:, first_name: "Léna") }

      it "sums up the answer" do
        expect(response).to have_http_status(:success)
        assert_select "h1", text: I18n.t("rsvp.answers.show.present_title")
        assert_select "dd", text: "Mélanie"
        assert_select "dd", text: "Léna"
        assert_select "a[href=?]", edit_rsvp_answer_path(token), text: I18n.t("rsvp.answers.show.edit")
      end
    end

    context "when nobody is coming" do
      let!(:melanie) { create(:family_member, :not_coming, family:, first_name: "Mélanie") }
      let!(:lena) { create(:family_member, :kid, :not_coming, family:, first_name: "Léna") }

      it "thanks them all the same" do
        assert_select "h1", text: I18n.t("rsvp.answers.show.absent_title")
        assert_select "dl", count: 0
      end
    end
  end
end
