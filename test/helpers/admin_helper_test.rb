require "test_helper"

class AdminHelperTest < ActionView::TestCase
  test "the countdown names the days left before the deadline" do
    travel_to Wedding::RSVP_DEADLINE - 12.days do
      assert_equal I18n.t("admin.countdown.remaining", count: 12), rsvp_countdown
    end
  end

  test "the deadline day itself counts as past, not as hours remaining" do
    travel_to Wedding::RSVP_DEADLINE.to_date.beginning_of_day do
      assert_equal I18n.t("admin.countdown.passed"), rsvp_countdown
    end
  end

  test "the countdown says so once the deadline has passed" do
    travel_to Wedding::RSVP_DEADLINE + 1.second do
      assert_equal I18n.t("admin.countdown.passed"), rsvp_countdown
    end
  end
end
