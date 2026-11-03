module AdminHelper
  def admin_nav_items
    [
      { label: t("admin.nav.dashboard"), path: admin_root_path },
      { label: t("admin.nav.families"), path: admin_families_path }
    ]
  end

  def age_group_label(group) = t("admin.family_members.age_groups.#{group}")

  def age_group_options = FamilyMember::AGE_GROUPS.map { |group| [ age_group_label(group), group ] }

  def attendance_label(attends)
    case attends
    when true then t("admin.family_members.attendance.coming")
    when false then t("admin.family_members.attendance.not_coming")
    else t("admin.family_members.attendance.unanswered")
    end
  end

  def attendance_options
    [ [ attendance_label(nil), "" ], [ attendance_label(true), "true" ], [ attendance_label(false), "false" ] ]
  end

  def member_tags(member)
    tags = []
    tags << t("admin.family_members.tags.run") if member.attends_run
    tags << t("admin.family_members.tags.brunch") if member.attends_brunch
    tags << t("admin.family_members.tags.no_alcohol") if member.no_alcohol && member.adult?
    tags << t("admin.family_members.tags.vegetarian") if member.vegetarian
    tags
  end

  def rsvp_countdown
    days = (Wedding::RSVP_DEADLINE.to_date - Time.zone.today).to_i

    days.positive? ? t("admin.countdown.remaining", count: days) : t("admin.countdown.passed")
  end
end
