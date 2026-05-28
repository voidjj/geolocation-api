# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
# Core: validations, serialization
require 'active_model/railtie'
# Background jobs processing (solid_queue)
require 'active_job/railtie'
# Database ORM and migrations
require 'active_record/railtie'
# File uploads to cloud storage (not needed for API)
# require 'active_storage/engine'
# HTTP routing and controllers (core for API)
require 'action_controller/railtie'
# Email sending (not needed for API)
# require 'action_mailer/railtie'
# Email receiving (not needed for API)
# require 'action_mailbox/engine'
# Rich text editor (not needed for API)
# require 'action_text/engine'
# HTML templating (not needed for JSON-only API)
# require 'action_view/railtie'
# WebSockets/ActionCable (required by solid_cable and rspec-rails)
require 'action_cable/engine'
# Rails test framework (using RSpec instead)
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module GeolocationApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
  end
end
