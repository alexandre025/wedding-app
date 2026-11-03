class Admin::DashboardController < Admin::BaseController
  def show
    @presenter = Admin::ResponseDashboardPresenter.new
  end
end
