require "rails_helper"

RSpec.describe AdminHelper do
  describe "#attendance_label" do
    it "names each of the three states apart" do
      expect(helper.attendance_label(true)).to eq(I18n.t("admin.family_members.attendance.coming"))
      expect(helper.attendance_label(false)).to eq(I18n.t("admin.family_members.attendance.not_coming"))
      expect(helper.attendance_label(nil)).to eq(I18n.t("admin.family_members.attendance.unanswered"))
    end
  end

  describe "#attendance_options" do
    subject(:options) { helper.attendance_options }

    it "offers the unanswered choice first" do
      expect(options.first).to eq([ I18n.t("admin.family_members.attendance.unanswered"), "" ])
    end

    it "offers values that cast back to the three states" do
      cast = options.map { |_caption, value| ActiveModel::Type::Boolean.new.cast(value) }

      expect(cast).to eq([ nil, true, false ])
    end
  end

  describe "#member_tags" do
    subject(:tags) { helper.member_tags(member) }

    let(:member) { build(:family_member) }

    it "names nothing for a member who has taken nothing up" do
      expect(tags).to be_empty
    end

    context "when the member runs" do
      let(:member) { build(:family_member, :runner) }

      it "names only that" do
        expect(tags).to eq([ I18n.t("admin.family_members.tags.run") ])
      end
    end

    context "when an adult does not drink" do
      let(:member) { build(:family_member, :teetotal) }

      it "names the alcohol tag" do
        expect(tags).to eq([ I18n.t("admin.family_members.tags.no_alcohol") ])
      end
    end

    context "when a teenager does not drink" do
      let(:member) { build(:family_member, :teen) }

      it "leaves the alcohol tag off, since the rule decided it" do
        expect(tags).to be_empty
      end
    end
  end

  describe "#rsvp_countdown" do
    it "names the days left before the deadline" do
      travel_to Wedding::RSVP_DEADLINE - 12.days do
        expect(helper.rsvp_countdown).to eq(I18n.t("admin.countdown.remaining", count: 12))
      end
    end

    it "says the deadline has passed once the day itself arrives" do
      travel_to Wedding::RSVP_DEADLINE.to_date.beginning_of_day do
        expect(helper.rsvp_countdown).to eq(I18n.t("admin.countdown.passed"))
      end
    end

    it "says so once the deadline is behind us" do
      travel_to Wedding::RSVP_DEADLINE + 1.second do
        expect(helper.rsvp_countdown).to eq(I18n.t("admin.countdown.passed"))
      end
    end
  end
end
