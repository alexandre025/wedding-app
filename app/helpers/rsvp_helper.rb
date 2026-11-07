module RsvpHelper
  def rsvp_diet_line(diet)
    parts = []
    parts << t("rsvp.answers.show.vegetarian") if diet.vegetarian
    parts << t("rsvp.answers.show.no_alcohol") if diet.no_alcohol
    parts << t("rsvp.answers.show.allergies", allergies: diet.allergies) if diet.allergies.present?

    t("rsvp.answers.show.diet_line", name: diet.name, details: parts.to_sentence)
  end
end
