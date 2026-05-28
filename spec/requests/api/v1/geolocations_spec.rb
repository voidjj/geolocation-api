# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Geolocations', type: :request do
  let(:api_key) { 'test-api-key' }
  let(:headers) { { 'X-API-Key' => api_key } }

  before { allow(ENV).to receive(:fetch).and_call_original }
  before { allow(ENV).to receive(:fetch).with('API_KEY', nil).and_return(api_key) }

  describe 'GET /api/v1/geolocations/:id' do
    context 'when geolocation exists' do
      let!(:geolocation) { create(:geolocation, host: 'example.com') }

      it 'returns 200 with geolocation data' do
        get '/api/v1/geolocations/example.com', headers: headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.dig('data', 'attributes', 'host')).to eq('example.com')
      end
    end

    context 'when geolocation does not exist' do
      let(:expected) { { error: 'Geolocation not found for: notfound.com' } }

      it 'returns 404' do
        get '/api/v1/geolocations/notfound.com', headers: headers

        expect(response).to have_http_status(:not_found)
        expect(response.body).to eq(expected.to_json)
      end
    end

    context 'without API key header' do
      it 'returns 401' do
        get '/api/v1/geolocations/example.com'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when API_KEY env var is not set' do
      before { allow(ENV).to receive(:fetch).with('API_KEY', nil).and_return(nil) }

      it 'returns 401 even with a header present' do
        get '/api/v1/geolocations/example.com', headers: headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/geolocations' do
    let(:params) { { geolocation: { host: 'example.com' } } }
    let(:created_geolocation) { build_stubbed(:geolocation, host: 'example.com', ip: '1.2.3.4') }

    context 'with valid host' do
      before do
        allow(GeolocationLookup).to receive(:call).with('example.com').and_return({})
        allow(GeolocationPersister).to receive(:call)
          .with(host: 'example.com', data: {})
          .and_return(created_geolocation)
      end

      it 'creates geolocation and returns 201' do
        post '/api/v1/geolocations', params: params, headers: headers

        expect(response).to have_http_status(:created)
        expect(response.parsed_body.dig('data', 'attributes', 'host')).to eq('example.com')
      end
    end

    context 'with duplicate host' do
      let(:expected) { { error: 'Geolocation already exists for: example.com' } }

      before do
        allow(GeolocationLookup).to receive(:call).and_return({})
        allow(GeolocationPersister).to receive(:call)
          .and_raise(GeolocationPersister::Error, 'Geolocation already exists for: example.com')
      end

      it 'returns 409 Conflict' do
        post '/api/v1/geolocations', params: params, headers: headers

        expect(response).to have_http_status(:conflict)
        expect(response.body).to eq(expected.to_json)
      end
    end

    context 'when lookup fails' do
      let(:expected) { { error: 'service unavailable' } }

      before { allow(GeolocationLookup).to receive(:call).and_raise(GeolocationLookup::Error, 'service unavailable') }

      it 'returns 422' do
        post '/api/v1/geolocations', params: params, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to eq(expected.to_json)
      end
    end
  end

  describe 'DELETE /api/v1/geolocations/:id' do
    context 'when geolocation exists' do
      let!(:geolocation) { create(:geolocation, host: 'example.com') }

      it 'deletes it and returns 204' do
        delete '/api/v1/geolocations/example.com', headers: headers

        expect(response).to have_http_status(:no_content)
        expect(Geolocation.find_by(host: 'example.com')).to be_nil
      end
    end

    context 'when geolocation does not exist' do
      let(:expected) { { error: 'Geolocation not found for: notfound.com' } }

      it 'returns 404' do
        delete '/api/v1/geolocations/notfound.com', headers: headers

        expect(response).to have_http_status(:not_found)
        expect(response.body).to eq(expected.to_json)
      end
    end
  end
end
