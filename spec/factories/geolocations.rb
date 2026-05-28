# frozen_string_literal: true

FactoryBot.define do
  factory :geolocation do
    sequence(:host) { |n| "example#{n}.com" }
    ip { Faker::Internet.ip_v4_address }
    country_code { Faker::Address.country_code }
    country_name { Faker::Address.country }
    region_name { Faker::Address.state }
    city { Faker::Address.city }
    zip { Faker::Address.zip_code }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
  end
end
