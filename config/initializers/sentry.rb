Sentry.init do |config|
  config.dsn = Rails.application.credentials.dig(:better_stack, :errors_dsn)
  config.enabled_environments = %w[ production ]
  config.send_default_pii = false
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]
  config.traces_sample_rate = 0
end
