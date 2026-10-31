module AdminRequests
  def admin_headers
    basic_auth_headers(
      Rails.application.config.x.admin.username,
      Rails.application.config.x.admin.password
    )
  end

  def basic_auth_headers(username, password)
    { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }
  end
end
