# frozen_string_literal: true

module GeolocationProviders
  class Error < StandardError; end
  class TimeoutError < Error; end
  class ConnectionError < Error; end
  class ApiError < Error; end
  class ValidationError < Error; end

  # Abstract base class for geolocation providers.
  # Subclasses must implement #fetch(host) and return a Hash with at minimum:
  #   ip, country_code, country_name, region_name, city, zip, latitude, longitude
  #
  # On failure, raise one of:
  #   GeolocationProviders::ApiError
  #   GeolocationProviders::TimeoutError
  #   GeolocationProviders::ConnectionError
  #   GeolocationProviders::ValidationError
  class Base
    def fetch(_host)
      raise NotImplementedError, "#{self.class} must implement #fetch"
    end
  end
end
