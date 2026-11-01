class Admin::ResponseDashboardPresenter
  Option = Struct.new(:label, :count, :of, :percent, :names)
  Diet = Struct.new(:label, :count)
  Pending = Struct.new(:name, :members, :emails)
  Answer = Struct.new(:name, :changed_at, :coming, :missing)

  MEMBER_NAMES = "string_agg(family_members.first_name, ', ' ORDER BY family_members.id)".freeze
  MEMBER_EMAILS = "string_agg(family_members.email, ',' ORDER BY family_members.id)".freeze
  ANSWERED_AT = "max(family_members.updated_at)".freeze

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
      Diet.new(I18n.t("admin.dashboard.show.diets.no_alcohol"), tally[:no_alcohol_count]),
      Diet.new(I18n.t("admin.dashboard.show.diets.allergies"), tally[:allergies_count])
    ]
  end

  def pending_families
    Family.pending
      .joins(:family_members)
      .group(:id)
      .order(:name)
      .pluck(:name, Arel.sql(MEMBER_NAMES), Arel.sql(MEMBER_EMAILS))
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
      @tally ||= FamilyMember.where(attends: true).pick(
        Arel.sql("count(*) filter (where attends_run)"),
        Arel.sql("#{MEMBER_NAMES} filter (where attends_run)"),
        Arel.sql("count(*) filter (where attends_brunch)"),
        Arel.sql("#{MEMBER_NAMES} filter (where attends_brunch)"),
        Arel.sql(teetotal),
        Arel.sql("count(*) filter (where btrim(coalesce(allergies, '')) <> '')")
      ).then { |row| %i[run_count run_names brunch_count brunch_names no_alcohol_count allergies_count].zip(row).to_h }
    end

    def teetotal
      FamilyMember.sanitize_sql_array(
        [ "count(*) filter (where no_alcohol and age_group = ?)", FamilyMember::ADULT ]
      )
    end

    def coming = "#{MEMBER_NAMES} filter (where family_members.attends)"

    def missing = "#{MEMBER_NAMES} filter (where not family_members.attends)"

    def option(label, count, names) = Option.new(label, count, present_count, share(count, present_count), names)

    def share(count, total = guests_count) = total.zero? ? 0 : ((count * 100.0) / total).round
end
