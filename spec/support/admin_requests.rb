module AdminRequests
  def admin_headers
    encoded = ActionController::HttpAuthentication::Basic.encode_credentials(
      Rails.application.config.x.admin.username,
      Rails.application.config.x.admin.password
    )

    { "HTTP_AUTHORIZATION" => encoded }
  end
end
