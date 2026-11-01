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

  def submitted_form_fields(body, scope: "family_member")
    document = Nokogiri::HTML5(body)
    fields = {}

    document.css("input[type=text], input[type=email]").each { |node| fields[node["name"]] = node["value"].to_s }
    document.css("textarea").each { |node| fields[node["name"]] = node.text }
    document.css("select").each do |node|
      selected = node.at_css("option[selected]")
      fields[node["name"]] = selected ? selected["value"] : ""
    end

    document.css("input[type=checkbox]").each { |node| fields[node["name"]] = node["checked"] ? "1" : "0" }

    fields.filter_map { |name, value| [ name[/\A#{scope}\[(.+)\]\z/, 1], value ] if name.start_with?(scope) }.to_h
  end
end
