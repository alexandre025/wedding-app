class Admin::FamiliesController < Admin::BaseController
  before_action :set_family, only: [ :show, :edit, :update, :destroy ]

  def index
    @query = search_params[Family::SEARCH_PREDICATE].to_s.strip
    @search = Family.ransack(search_params)
    @families = @search.result(distinct: true).includes(:family_members).order(:name)

    @families_count = Family.count
    @guests_count = FamilyMember.count
    @answered_count = Family.where.not(answered_at: nil).count
  end

  def show
  end

  def new
    @form = Admin::FamilyForm.new(Family.new)
  end

  def create
    @form = Admin::FamilyForm.new(Family.new)

    if @form.submit(family_params)
      redirect_to new_admin_family_member_path(@form.id), notice: t("admin.families.create.created", name: @form.name)
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @form = Admin::FamilyForm.new(@family)
  end

  def update
    @form = Admin::FamilyForm.new(@family)

    if @form.submit(family_params)
      redirect_to admin_family_path(@family), notice: t("admin.families.update.updated", name: @family.name)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    name = @family.name
    @family.destroy

    redirect_to admin_families_path, notice: t("admin.families.destroy.destroyed", name:)
  end

  private
    def set_family
      @family = Family.find(params[:id])
    end

    def family_params
      params.require(:family).permit(:name)
    end

    def search_params
      params[:q].is_a?(ActionController::Parameters) ? params[:q].permit(Family::SEARCH_PREDICATE) : {}
    end
end
