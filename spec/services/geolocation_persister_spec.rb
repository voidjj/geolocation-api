# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GeolocationPersister do
  describe '.call' do
    let(:data) do
      {
        'ip' => '1.2.3.4',
        'country_code' => 'US',
        'country_name' => 'United States',
        'region_name' => 'California',
        'city' => 'Los Angeles',
        'zip' => '90001',
        'latitude' => 34.0522,
        'longitude' => -118.2437,
      }
    end

    it 'creates and returns a Geolocation record' do
      geolocation = described_class.call(host: 'example.com', data:)

      expect(geolocation).to be_a(Geolocation)
      expect(geolocation).to be_persisted
      expect(geolocation.host).to eq('example.com')
      expect(geolocation.ip).to eq('1.2.3.4')
      expect(geolocation.country_code).to eq('US')
    end

    it 'returns existing record on subsequent calls (idempotent)' do
      first = described_class.call(host: 'example.com', data:)
      second = described_class.call(host: 'example.com', data:)

      expect(second.id).to eq(first.id)
      expect(second).to be_persisted
    end

    it 'returns existing record without modification' do
      existing = described_class.call(host: 'example.com', data:)
      original_ip = existing.ip

      new_data = data.merge('ip' => '9.9.9.9', 'city' => 'Different City')
      result = described_class.call(host: 'example.com', data: new_data)

      expect(result.id).to eq(existing.id)
      expect(result.ip).to eq(original_ip)
      expect(result.city).to eq('Los Angeles')
    end
  end
end
