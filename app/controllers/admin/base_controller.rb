module Admin
  # The couple's own back office: its own chrome, behind HTTP Basic.
  class BaseController < ApplicationController
    layout "admin"

    before_action :authenticate_couple

    private
      # Compared per request rather than at class load, so booting production to
      # precompile assets needs no credentials. Blank expected values deny
      # everyone, which is the safe way for a misconfigured deploy to fail.
      def authenticate_couple
        authenticate_or_request_with_http_basic(t("admin.realm")) do |username, password|
          expected_username = Rails.application.config.x.admin.username
          expected_password = Rails.application.config.x.admin.password
          next false if expected_username.blank? || expected_password.blank?

          # `&` rather than `&&`: no short circuit, so no timing signal.
          ActiveSupport::SecurityUtils.secure_compare(username, expected_username) &
            ActiveSupport::SecurityUtils.secure_compare(password, expected_password)
        end
      end
  end
end
