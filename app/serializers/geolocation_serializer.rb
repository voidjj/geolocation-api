# frozen_string_literal: true

class GeolocationSerializer
  include JSONAPI::Serializer

  attributes :host, :ip, :country_code, :country_name, :region_name, :city, :zip, :latitude, :longitude
end
