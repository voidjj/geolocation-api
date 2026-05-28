# frozen_string_literal: true

# Environment variables are validated lazily where they're used:
# - API_KEY: validated in Api::V1::BaseController#authenticate_api_key (returns 401 if missing)
# - IPSTACK_API_KEY: validated in GeolocationProviders::Ipstack#fetch (raises ApiError if missing)
#
# This allows running tasks like db:create, assets:precompile without setting these keys.
