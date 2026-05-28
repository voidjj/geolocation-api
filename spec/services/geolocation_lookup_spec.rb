# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GeolocationLookup do
  let(:provider) { instance_double(GeolocationProviders::Ipstack) }
  let(:provider_class) { class_double(GeolocationProviders::Ipstack, new: provider) }

  subject(:lookup) { described_class.new(provider: provider_class) }

  before { Rails.cache.clear }

  describe '.call' do
    it 'delegates to a new instance' do
      allow_any_instance_of(described_class)
        .to receive(:fetch_with_cache).with('1.2.3.4')
        .and_return({ 'ip' => '1.2.3.4' })

      result = described_class.call('1.2.3.4')

      expect(result).to eq({ 'ip' => '1.2.3.4' })
    end
  end

  describe '#call' do
    it 'calls fetch on the provider' do
      allow(provider).to receive(:fetch).with('example.com').and_return({ 'ip' => '1.2.3.4' })

      result = lookup.call('example.com')

      expect(result).to eq({ 'ip' => '1.2.3.4' })
    end

    it 're-raises GeolocationLookup::Error from provider' do
      allow(provider).to receive(:fetch).and_raise(GeolocationProviders::TimeoutError, 'timeout')

      expect { lookup.call('example.com') }.to raise_error(GeolocationLookup::Error)
    end

    context 'when CACHE_TTL is non-zero' do
      around do |example|
        original = Rails.cache
        Rails.cache = ActiveSupport::Cache::MemoryStore.new
        example.run
        Rails.cache = original
      end

      it 'caches the result and does not call provider again on second call' do
        allow(provider).to receive(:fetch).with('example.com').and_return({ 'ip' => '1.2.3.4' }).once

        lookup.call('example.com')
        lookup.call('example.com')

        expect(provider).to have_received(:fetch).once
      end
    end

    context 'when CACHE_TTL is 0' do
      before { stub_const('GeolocationLookup::CACHE_TTL', 0) }

      it 'always calls provider without caching' do
        allow(provider).to receive(:fetch).with('example.com').and_return({ 'ip' => '1.2.3.4' })

        lookup.call('example.com')
        lookup.call('example.com')

        expect(provider).to have_received(:fetch).twice
      end
    end
  end
end
