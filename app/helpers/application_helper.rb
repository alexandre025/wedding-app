module ApplicationHelper
  # The three destinations shared by the desktop header and the mobile tab bar.
  def main_nav_items
    [
      {label: t("nav.home"), path: root_path, icon: "home"},
      {label: t("nav.schedule"), path: schedule_path, icon: "calendar"},
      {label: t("nav.rsvp"), path: rsvp_path, icon: "mail"}
    ]
  end

  # Inline stroke icon from app/views/shared/icons.
  def icon(name, class_name: "size-[22px]")
    render "shared/icons/#{name}", class_name: class_name
  end
end
