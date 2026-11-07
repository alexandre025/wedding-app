class Rsvp::AnswerForm < ApplicationForm
  attribute :members
  attribute :song

  after_assign_form_attributes :assign_members, :normalize

  validate :every_member_answered

  attr_reader :family, :member_forms

  def setup(family)
    @family = family
    @member_forms = family.family_members.map { |member| Rsvp::MemberAnswerForm.new(member) }
    self.song = family.song
  end

  def any_present? = member_forms.any?(&:attends)

  def perform
    Family.transaction do
      member_forms.each(&:perform)
      family.song = song
      family.save!
    end
  end

  private
    def assign_members
      member_forms.each do |form|
        form.assign_form_attributes(submitted_answer_for(form.family_member))
      end
    end

    def normalize
      self.song = any_present? ? song&.strip.presence : nil
    end

    def submitted_answer_for(family_member)
      answer = members[family_member.id.to_s] if members.respond_to?(:key?)
      answer.respond_to?(:key?) ? answer : {}
    end

    def every_member_answered
      errors.add(:base, :unanswered) unless member_forms.all?(&:answered?)
    end
end
