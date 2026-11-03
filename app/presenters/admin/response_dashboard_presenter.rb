class Admin::ResponseDashboardPresenter
  Option = Struct.new(:label, :count, :of, :percent, :names)
  Diet = Struct.new(:label, :count)
  Pending = Struct.new(:name, :members)
  Answer = Struct.new(:name, :changed_at, :coming, :missing)

  MEMBER_NAMES = "string_agg(family_members.first_name, ', ' ORDER BY family_members.id)".freeze
  ANSWERED_AT = "max(family_members.updated_at)".freeze

  ADULTS = "age_group = '#{FamilyMember::ADULT}'".freeze

  TALLY = {
    run_count: "count(*) filter (where attends_run)",
    run_names: "#{MEMBER_NAMES} filter (where attends_run)",
    brunch_count: "count(*) filter (where attends_brunch)",
    brunch_names: "#{MEMBER_NAMES} filter (where attends_brunch)",
    alcohol_count: "count(*) filter (where not no_alcohol and #{ADULTS})",
    no_alcohol_count: "count(*) filter (where no_alcohol and #{ADULTS})",
    vegetarian_count: "count(*) filter (where vegetarian)",
    allergies_count: "count(*) filter (where btrim(coalesce(allergies, '')) <> '')"
  }.freeze

  def families_count = Family.count

  def answered_families_count = Family.answered.count

  def guests_count = attendance.values.sum

  def present_count = attendance.fetch(true, 0)

  def absent_count = attendance.fetch(false, 0)

  def pending_count = attendance.fetch(nil, 0)

  def present_percent = share(present_count)

  def absent_percent = share(absent_count)

  def pending_percent = guests_count.zero? ? 0 : 100 - present_percent - absent_percent

  def answered_percent = share(present_count + absent_count)

  def sunday_options
    [
      option(I18n.t("admin.dashboard.show.options.run"), tally[:run_count], tally[:run_names]),
      option(I18n.t("admin.dashboard.show.options.brunch"), tally[:brunch_count], tally[:brunch_names])
    ]
  end

  def diets
    [
      Diet.new(I18n.t("admin.dashboard.show.diets.alcohol"), tally[:alcohol_count]),
      Diet.new(I18n.t("admin.dashboard.show.diets.no_alcohol"), tally[:no_alcohol_count]),
      Diet.new(I18n.t("admin.dashboard.show.diets.vegetarian"), tally[:vegetarian_count]),
      Diet.new(I18n.t("admin.dashboard.show.diets.allergies"), tally[:allergies_count])
    ]
  end

  def pending_families
    Family.pending
      .joins(:family_members)
      .group(:id)
      .order(:name)
      .pluck(:name, Arel.sql(MEMBER_NAMES))
      .map { |row| Pending.new(*row) }
  end

  def recent_answers
    Family.answered
      .joins(:family_members)
      .group(:id)
      .order(Arel.sql("#{ANSWERED_AT} desc"))
      .pluck(:name, Arel.sql(ANSWERED_AT), Arel.sql(coming), Arel.sql(missing))
      .map { |row| Answer.new(*row) }
  end

  private
    def attendance = @attendance ||= FamilyMember.group(:attends).count

    def tally
      @tally ||= TALLY.keys.zip(FamilyMember.where(attends: true).pick(*TALLY.values.map { Arel.sql(_1) })).to_h
    end

    def coming = "#{MEMBER_NAMES} filter (where family_members.attends)"

    def missing = "#{MEMBER_NAMES} filter (where not family_members.attends)"

    def option(label, count, names) = Option.new(label, count, present_count, share(count, present_count), names)

    def share(count, total = guests_count) = total.zero? ? 0 : ((count * 100.0) / total).round
end
