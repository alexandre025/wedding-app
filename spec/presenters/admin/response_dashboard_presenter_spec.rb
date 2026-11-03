require "rails_helper"

RSpec.describe Admin::ResponseDashboardPresenter do
  subject(:presenter) { described_class.new }

  let(:melchior) { create(:family, name: "Melchior") }
  let(:dubois) { create(:family, name: "Dubois") }
  let(:roux) { create(:family, name: "Roux") }

  let(:melanie) do
    create(:family_member, :coming, :runner, :brunching, :with_allergies, family: melchior, first_name: "Mélanie")
  end

  let(:sylvain) { create(:family_member, :coming, :teetotal, family: melchior, first_name: "Sylvain") }
  let(:lena) { create(:family_member, :not_coming, family: melchior, first_name: "Léna") }
  let(:antoine) { create(:family_member, :with_email, family: roux, first_name: "Antoine") }

  let(:helene) do
    travel_to(2.days.ago) { create(:family_member, :coming, family: dubois, first_name: "Hélène") }
  end

  let!(:guest_list) { [ melanie, sylvain, lena, antoine, helene ] }

  describe "#guests_count" do
    it "counts every member of every family" do
      expect(presenter.guests_count).to eq(5)
    end
  end

  describe "#present_count" do
    it "counts the guests who are coming" do
      expect(presenter.present_count).to eq(3)
    end
  end

  describe "#absent_count" do
    it "counts the refusals, and keeps them apart from the unanswered" do
      expect(presenter.absent_count).to eq(1)
    end
  end

  describe "#pending_count" do
    it "counts the guests who have not answered" do
      expect(presenter.pending_count).to eq(1)
    end
  end

  describe "#answered_percent" do
    it "counts a refusal as an answer" do
      expect(presenter.answered_percent).to eq(80)
    end
  end

  describe "#pending_percent" do
    it "takes what the other two segments leave, so the bar fills" do
      expect(presenter.pending_percent).to eq(100 - presenter.present_percent - presenter.absent_percent)
    end

    context "with a guest list that rounds badly" do
      let!(:guest_list) { [ melanie, lena, antoine ] }

      it "still leaves the three segments summing to 100" do
        expect([ presenter.present_percent, presenter.absent_percent, presenter.pending_percent ])
          .to eq([ 33, 33, 34 ])
      end
    end

    context "with no guests at all" do
      let!(:guest_list) { [] }

      it "returns zero rather than dividing by nothing" do
        expect(presenter.pending_percent).to eq(0)
        expect(presenter.answered_percent).to eq(0)
      end
    end
  end

  describe "#families_count" do
    it "counts every family, answered or not" do
      expect(presenter.families_count).to eq(3)
    end
  end

  describe "#answered_families_count" do
    it "counts the families whose members have all answered" do
      expect(presenter.answered_families_count).to eq(2)
    end
  end

  describe "#sunday_options" do
    subject(:run) { presenter.sunday_options.first }

    it "names the event and counts the runners against the guests who are coming" do
      expect(run).to have_attributes(label: I18n.t("admin.dashboard.show.options.run"), count: 1, of: 3,
        percent: 33, names: "Mélanie")
    end

    context "when a guest who is not coming has ticked the option" do
      let(:lena) { create(:family_member, :not_coming, :runner, family: melchior, first_name: "Léna") }

      it "leaves them out" do
        expect(run.count).to eq(1)
      end
    end

    context "with nobody coming" do
      let!(:guest_list) { [ antoine ] }

      it "returns zero rather than dividing by nothing" do
        expect(run).to have_attributes(count: 0, of: 0, percent: 0, names: nil)
      end
    end
  end

  describe "#diets" do
    subject(:alcohol) { presenter.diets.first }

    let(:no_alcohol) { presenter.diets.second }

    it "counts the adults who are coming and drink" do
      expect(alcohol).to have_attributes(label: I18n.t("admin.dashboard.show.diets.alcohol"), count: 2)
    end

    it "counts the adults who are coming and do not" do
      expect(no_alcohol).to have_attributes(label: I18n.t("admin.dashboard.show.diets.no_alcohol"), count: 1)
    end

    context "when an adult who is coming stops drinking" do
      let(:melanie) do
        create(:family_member, :coming, :runner, :brunching, :with_allergies, :teetotal, family: melchior,
          first_name: "Mélanie")
      end

      it "moves them from one row to the other" do
        expect([ alcohol.count, no_alcohol.count ]).to eq([ 1, 2 ])
      end
    end

    context "when a teenager is coming" do
      let(:lena) { create(:family_member, :teen, :coming, family: melchior, first_name: "Léna") }

      it "leaves them out of both, since nobody under age is the caterer's to pour for" do
        expect([ alcohol.count, no_alcohol.count ]).to eq([ 2, 1 ])
      end
    end

    context "when guests are vegetarian" do
      subject(:vegetarian) { presenter.diets.third }

      let(:sylvain) { create(:family_member, :coming, :vegetarian, family: melchior, first_name: "Sylvain") }
      let(:lena) { create(:family_member, :kid, :coming, :vegetarian, family: melchior, first_name: "Léna") }
      let(:antoine) { create(:family_member, :vegetarian, family: roux, first_name: "Antoine") }

      it "counts those who are coming, whatever their age" do
        expect(vegetarian).to have_attributes(label: I18n.t("admin.dashboard.show.diets.vegetarian"), count: 2)
      end
    end

    it "counts no vegetarian when nobody is" do
      expect(presenter.diets.third).to have_attributes(label: I18n.t("admin.dashboard.show.diets.vegetarian"), count: 0)
    end

    it "counts the guests who signalled an allergy" do
      expect(presenter.diets.last).to have_attributes(label: I18n.t("admin.dashboard.show.diets.allergies"), count: 1)
    end
  end

  describe "#pending_families" do
    it "lists the families still owing an answer, and who is in them" do
      expect(presenter.pending_families).to contain_exactly(have_attributes(name: "Roux", members: "Antoine"))
    end

    context "when a family has no members at all" do
      let!(:guest_list) { [ melanie, sylvain, lena ].tap { roux } }

      it "counts it as neither answered nor pending" do
        expect(presenter.pending_families).to be_empty
        expect(presenter.answered_families_count).to eq(1)
      end
    end
  end

  describe "#recent_answers" do
    it "lists the answered families, most recently touched first" do
      expect(presenter.recent_answers.map(&:name)).to eq([ "Melchior", "Dubois" ])
    end

    it "names who is coming and who is not" do
      expect(presenter.recent_answers.first).to have_attributes(coming: "Mélanie, Sylvain", missing: "Léna")
    end

    it "leaves the refusals nil when everyone in the family is coming" do
      expect(presenter.recent_answers.last.missing).to be_nil
    end
  end
end
