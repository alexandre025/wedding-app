class HeartbeatJob < ApplicationJob
  def perform
    url = Rails.application.credentials.dig(:better_stack, :heartbeat_url)
    Net::HTTP.get(URI(url)) if url.present?
  end
end
