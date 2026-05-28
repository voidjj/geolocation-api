# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GeolocationProviders::Ipstack do
  subject(:provider) { described_class.new(api_key: 'test_key', security: 0) }

  let(:base_url) { 'https://api.ipstack.com' }

  let(:valid_response) do
    {
      ip: '1.2.3.4',
      type: 'ipv4',
      country_code: 'US',
      country_name: 'United States',
      region_code: 'CA',
      region_name: 'California',
      city: 'Los Angeles',
      zip: '90001',
      latitude: 34.0522,
      longitude: -118.2437,
    }.to_json
  end

  describe '#fetch' do
    context 'with a successful response' do
      before do
        stub_request(:get, "#{base_url}/1.2.3.4")
          .with(query: hash_including('access_key' => 'test_key'))
          .to_return(status: 200, body: valid_response, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns parsed geolocation data' do
        result = provider.fetch('1.2.3.4')

        expect(result['ip']).to eq('1.2.3.4')
        expect(result['country_code']).to eq('US')
        expect(result['city']).to eq('Los Angeles')
      end
    end

    context 'when API key is missing' do
      subject(:provider) { described_class.new(api_key: nil) }

      it 'raises GeolocationProviders::ApiError' do
        expect do
          provider.fetch('1.2.3.4')
        end.to raise_error(GeolocationProviders::ApiError, 'API key not configured')
      end
    end

    context 'when ipstack returns an error response' do
      before do
        stub_request(:get, "#{base_url}/1.2.3.4")
          .with(query: hash_including('access_key' => 'test_key'))
          .to_return(
            status: 200,
            body: { success: false, error: { code: 101, info: 'Invalid API key' } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises GeolocationProviders::ApiError' do
        expect { provider.fetch('1.2.3.4') }.to raise_error(GeolocationProviders::ApiError, /101/)
      end
    end

    context 'when response has invalid JSON' do
      before do
        stub_request(:get, "#{base_url}/1.2.3.4")
          .with(query: hash_including('access_key' => 'test_key'))
          .to_return(status: 200, body: 'not json', headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises GeolocationProviders::ValidationError' do
        expect { provider.fetch('1.2.3.4') }.to raise_error(GeolocationProviders::ValidationError, /Invalid JSON/)
      end
    end

    context 'when response is missing required fields' do
      before do
        stub_request(:get, "#{base_url}/1.2.3.4")
          .with(query: hash_including('access_key' => 'test_key'))
          .to_return(status: 200, body: { ip: '1.2.3.4' }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises GeolocationProviders::ValidationError' do
        expect do
          provider.fetch('1.2.3.4')
        end.to raise_error(GeolocationProviders::ValidationError, /Invalid API response/)
      end
    end

    context 'when request times out' do
      before do
        stub_request(:get, "#{base_url}/1.2.3.4")
          .with(query: hash_including('access_key' => 'test_key'))
          .to_timeout
      end

      it 'raises GeolocationProviders::TimeoutError' do
        expect { provider.fetch('1.2.3.4') }.to raise_error(GeolocationProviders::TimeoutError, 'Request timeout')
      end
    end

    context 'when connection fails' do
      before do
        stub_request(:get, "#{base_url}/1.2.3.4")
          .with(query: hash_including('access_key' => 'test_key'))
          .to_raise(Faraday::ConnectionFailed.new('connection refused'))
      end

      it 'raises GeolocationProviders::ConnectionError' do
        expect do
          provider.fetch('1.2.3.4')
        end.to raise_error(GeolocationProviders::ConnectionError, 'Connection failed')
      end
    end

    context 'when HTTP returns non-200 status' do
      before do
        stub_request(:get, "#{base_url}/1.2.3.4")
          .with(query: hash_including('access_key' => 'test_key'))
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'raises GeolocationProviders::ApiError' do
        expect { provider.fetch('1.2.3.4') }.to raise_error(GeolocationProviders::ApiError, /HTTP 500/)
      end
    end
  end
end
