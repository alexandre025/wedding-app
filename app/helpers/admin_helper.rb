module AdminHelper
  def admin_nav_items
    [
      { label: t("admin.nav.dashboard"), path: admin_root_path }
    ]
  end

  def rsvp_countdown
    days = (Wedding::RSVP_DEADLINE - Date.current).to_i

    days.positive? ? t("admin.countdown.remaining", count: days) : t("admin.countdown.passed")
  end
end
