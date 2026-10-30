module AdminHelper
  # The admin destinations. Mirrors main_nav_items; grows as screens land.
  def admin_nav_items
    [
      { label: t("admin.nav.dashboard"), path: admin_root_path }
    ]
  end

  # "plus que 412 jours", or that the deadline has passed.
  def rsvp_countdown
    days = (Wedding::RSVP_DEADLINE - Date.current).to_i

    days.positive? ? t("admin.countdown.remaining", count: days) : t("admin.countdown.passed")
  end
end
