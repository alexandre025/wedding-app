class Admin::BaseController < ApplicationController
  layout "admin"

  before_action :authenticate_couple, unless: -> { Rails.application.config.x.admin.skip_authentication }

  private
    def authenticate_couple
      authenticate_or_request_with_http_basic(t("admin.realm")) do |username, password|
        expected_username = Rails.application.config.x.admin.username
        expected_password = Rails.application.config.x.admin.password
        next false if expected_username.blank? || expected_password.blank?

        ActiveSupport::SecurityUtils.secure_compare(username, expected_username) &
          ActiveSupport::SecurityUtils.secure_compare(password, expected_password)
      end
    end
end
