ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Credentials for the admin screens, which sit behind HTTP Basic.
    def admin_headers
      encoded = ActionController::HttpAuthentication::Basic.encode_credentials(
        Rails.application.config.x.admin.username,
        Rails.application.config.x.admin.password
      )

      { "HTTP_AUTHORIZATION" => encoded }
    end
  end
end
