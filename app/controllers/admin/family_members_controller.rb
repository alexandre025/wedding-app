class Admin::FamilyMembersController < Admin::BaseController
  before_action :set_family, only: [ :new, :create ]
  before_action :set_family_member, only: [ :edit, :update, :destroy ]

  def new
    @form = Admin::FamilyMemberForm.new(@family.family_members.build)
  end

  def create
    @form = Admin::FamilyMemberForm.new(@family.family_members.build)

    if @form.submit(family_member_params)
      redirect_to admin_family_path(@family), notice: t("admin.family_members.create.created", name: @form.first_name)
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @form = Admin::FamilyMemberForm.new(@family_member)
  end

  def update
    @form = Admin::FamilyMemberForm.new(@family_member)

    if @form.submit(family_member_params)
      redirect_to admin_family_path(@family), notice: t("admin.family_members.update.updated", name: @family_member.first_name)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    name = @family_member.first_name
    @family_member.destroy

    redirect_to admin_family_path(@family), notice: t("admin.family_members.destroy.destroyed", name: name)
  end

  private
    def set_family
      @family = Family.find(params[:family_id])
    end

    def set_family_member
      @family_member = FamilyMember.find(params[:id])
      @family = @family_member.family
    end

    def family_member_params
      params.require(:family_member).permit(:first_name, :email)
    end
end
