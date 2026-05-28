# frozen_string_literal: true

# Disable Rails encrypted credentials for this API
# We use environment variables (ENV) exclusively for configuration
Rails.application.config.require_master_key = false
