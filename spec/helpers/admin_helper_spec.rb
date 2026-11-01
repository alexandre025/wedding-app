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
    it "offers the unanswered choice first" do
      expect(helper.attendance_options.first).to eq([ I18n.t("admin.family_members.attendance.unanswered"), "" ])
    end

    it "offers values that cast back to the three states" do
      cast = helper.attendance_options.map { |_caption, value| ActiveModel::Type::Boolean.new.cast(value) }

      expect(cast).to eq([ nil, true, false ])
    end
  end

  describe "#member_tags" do
    it "names nothing for a member who has taken nothing up" do
      expect(helper.member_tags(build(:family_member))).to be_empty
    end

    it "names only the options taken up" do
      member = build(:family_member, :runner)

      expect(helper.member_tags(member)).to eq([ I18n.t("admin.family_members.tags.run") ])
    end

    it "names the alcohol tag for an adult who does not drink" do
      member = build(:family_member, :teetotal)

      expect(helper.member_tags(member)).to eq([ I18n.t("admin.family_members.tags.no_alcohol") ])
    end

    it "leaves the alcohol tag off a teenager, who is kept off it by rule" do
      member = build(:family_member, :teen)

      expect(helper.member_tags(member)).to be_empty
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
