class Admin::FamilyForm < ApplicationForm
  proxy_for Family, :@family

  attribute :name

  after_assign_form_attributes :normalize

  validates :name, presence: true

  attr_reader :family

  def setup(family)
    @family = family
    self.name = family.name
  end

  def perform
    @family.name = name

    @family.save!
  end

  private
    def normalize
      self.name = name&.strip
    end
end
