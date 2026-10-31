require "rails_helper"

RSpec.describe AdminHelper do
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
