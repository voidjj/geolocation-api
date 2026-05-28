# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

[
  {
    host: '8.8.8.8',
    ip: '8.8.8.8',
    country_code: 'US',
    country_name: 'United States',
    region_name: 'Virginia',
    city: 'Ashburn',
    zip: '20149',
    latitude: 39.01878738,
    longitude: -77.53931427,
  },
  {
    host: '1.1.1.1',
    ip: '1.1.1.1',
    country_code: 'AU',
    country_name: 'Australia',
    region_name: 'Queensland',
    city: 'South Brisbane',
    zip: '4101',
    latitude: -27.47561264,
    longitude: 153.01708984,
  },
  {
    host: 'github.com',
    ip: '140.82.121.4',
    country_code: 'US',
    country_name: 'United States',
    region_name: 'Washington',
    city: 'Seattle',
    zip: '98101',
    latitude: 47.60621643,
    longitude: -122.33206177,
  },
  {
    host: 'example.com',
    ip: '93.184.216.34',
    country_code: 'US',
    country_name: 'United States',
    region_name: 'Massachusetts',
    city: 'Norwell',
    zip: '02061',
    latitude: 42.15709305,
    longitude: -70.82499695,
  },
].each do |attrs|
  Geolocation.find_or_create_by!(host: attrs[:host]) do |geo|
    geo.assign_attributes(attrs)
  end
end

Rails.logger.debug { "Seeded #{Geolocation.count} geolocation records." }
