# frozen_string_literal: true

class GeolocationLookup
  class Error < StandardError; end

  CACHE_TTL = ENV.fetch('GEOLOCATION_CACHE_TTL', 1.day.to_i).to_i

  def initialize(provider: GeolocationProviders::Ipstack)
    @provider = provider
  end

  def self.call(...)
    new.call(...)
  end

  def call(host)
    fetch_with_cache(host)
  rescue GeolocationProviders::TimeoutError => e
    raise Error, "Timeout: #{e.message}"
  rescue GeolocationProviders::ConnectionError => e
    raise Error, "Connection failed: #{e.message}"
  rescue GeolocationProviders::ApiError, GeolocationProviders::ValidationError => e
    raise Error, e.message
  end

  private

  attr_reader :provider

  def fetch_with_cache(host)
    return provider.new.fetch(host) if CACHE_TTL.zero?

    Rails.cache.fetch("geolocation/#{host}", expires_in: CACHE_TTL) do
      provider.new.fetch(host)
    end
  end
end
