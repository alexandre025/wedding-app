module AdminHelper
  def admin_nav_items
    [
      { label: t("admin.nav.dashboard"), path: admin_root_path },
      { label: t("admin.nav.families"), path: admin_families_path }
    ]
  end

  def age_group_label(group) = t("admin.family_members.age_groups.#{group}")

  def age_group_options = FamilyMember::AGE_GROUPS.map { |group| [ age_group_label(group), group ] }

  def rsvp_countdown
    days = (Wedding::RSVP_DEADLINE.to_date - Time.zone.today).to_i

    days.positive? ? t("admin.countdown.remaining", count: days) : t("admin.countdown.passed")
  end
end
