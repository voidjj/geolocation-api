# frozen_string_literal: true

module GeolocationProviders
  class Ipstack < Base
    BASE_URL = 'https://api.ipstack.com'
    DEFAULT_TIMEOUT = 5

    # Security module options for ipstack API
    SECURITY_OPTIONS = {
      disabled: 0,
      enabled: 1,
    }.freeze
    DEFAULT_SECURITY = SECURITY_OPTIONS[:enabled]

    RESPONSE_SCHEMA = Dry::Schema.JSON do
      required(:ip).filled(:string)
      required(:type).filled(:string)
      required(:country_code).filled(:string)
      required(:country_name).filled(:string)
      required(:region_code).filled(:string)
      required(:region_name).filled(:string)
      required(:city).filled(:string)
      required(:zip).filled(:string)
      required(:latitude).filled(:float)
      required(:longitude).filled(:float)
    end

    def initialize(
      api_key: ENV.fetch('IPSTACK_API_KEY', nil),
      timeout: DEFAULT_TIMEOUT,
      security: ENV.fetch('IPSTACK_SECURITY', DEFAULT_SECURITY).to_i
    )
      super()
      @api_key = api_key
      @timeout = timeout
      @security = security
    end

    def fetch(host)
      raise ApiError, 'API key not configured' if api_key.blank?

      response = http_client.get("/#{host}", request_params)

      raise ApiError, "HTTP #{response.status}: #{response.body}" unless response.status == 200

      data = JSON.parse(response.body)

      if data['success'] == false
        raise ApiError, "ipstack error #{data.dig('error', 'code')}: #{data.dig('error', 'info')}"
      end

      validate_response!(data)
    rescue Faraday::TimeoutError, Net::OpenTimeout, Net::ReadTimeout, Errno::ETIMEDOUT
      raise TimeoutError, 'Request timeout'
    rescue Faraday::ConnectionFailed => e
      if e.wrapped_exception.is_a?(Net::OpenTimeout) || e.wrapped_exception.is_a?(Errno::ETIMEDOUT)
        raise TimeoutError,
              'Request timeout'
      end

      raise ConnectionError, 'Connection failed'
    rescue Faraday::Error => e
      raise ConnectionError, "HTTP client error: #{e.message}"
    rescue JSON::ParserError => e
      raise ValidationError, "Invalid JSON response: #{e.message}"
    end

    private

    attr_reader :api_key, :timeout, :security

    def http_client
      @http_client ||= Faraday.new(
        url: BASE_URL,
        request: { timeout: timeout }
      ) do |f|
        f.adapter Faraday.default_adapter
      end
    end

    def request_params
      {
        access_key: api_key,
        security: security,
        output: 'json',
      }
    end

    def validate_response!(data)
      result = RESPONSE_SCHEMA.call(data)
      unless result.success?
        raise ValidationError,
              "Invalid API response: #{result.errors.to_h}"
      end

      result.to_h.transform_keys(&:to_s)
    end
  end
end
