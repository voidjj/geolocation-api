# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Geolocation, type: :model do
  subject { build(:geolocation) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:host) }
    it { is_expected.to validate_uniqueness_of(:host) }
    it { is_expected.to validate_presence_of(:ip) }

    context 'host format' do
      it 'accepts a valid domain' do
        expect(build(:geolocation, host: 'example.com')).to be_valid
      end

      it 'accepts a valid IP address' do
        expect(build(:geolocation, host: '8.8.8.8')).to be_valid
      end

      it 'rejects an invalid host' do
        expect(build(:geolocation, host: 'not_valid')).not_to be_valid
      end
    end
  end
end
