class Rsvp::AnswerPresenter
  Diet = Struct.new(:name, :vegetarian, :no_alcohol, :allergies)

  attr_reader :family

  def initialize(family)
    @family = family
    @members = family.family_members.to_a
  end

  def any_present? = present.any?

  def present_names = present.map(&:first_name)

  def absent_names = @members.select { |member| member.attends == false }.map(&:first_name)

  def run_names = present.select(&:attends_run).map(&:first_name)

  def brunch_names = present.select(&:attends_brunch).map(&:first_name)

  def song = family.song

  def diets
    present.filter_map do |member|
      diet = Diet.new(member.first_name, member.vegetarian, member.adult? && member.no_alcohol, member.allergies)
      diet if diet.vegetarian || diet.no_alcohol || diet.allergies.present?
    end
  end

  private
    def present = @members.select(&:attends)
end
