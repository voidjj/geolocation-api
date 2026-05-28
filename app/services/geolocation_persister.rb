# frozen_string_literal: true

class GeolocationPersister
  class Error < StandardError; end

  def initialize(host:, data:)
    @host = host
    @data = data
  end

  def self.call(...)
    new(...).call
  end

  def call
    Geolocation.find_or_create_by!(host: host) do |geo|
      geo.ip = data['ip']
      geo.country_code = data['country_code']
      geo.country_name = data['country_name']
      geo.region_name = data['region_name']
      geo.city = data['city']
      geo.zip = data['zip']
      geo.latitude = data['latitude']
      geo.longitude = data['longitude']
    end
  rescue ActiveRecord::RecordNotUnique
    raise Error, "Geolocation already exists for: #{host}"
  rescue ActiveRecord::RecordInvalid => e
    raise Error, e.message
  end

  private

  attr_reader :host, :data
end
