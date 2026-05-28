# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      class Unauthorized < StandardError; end

      before_action :authenticate_api_key

      rescue_from Unauthorized, with: :unauthorized

      private

      def authenticate_api_key
        configured_key = ENV.fetch('API_KEY', nil)
        return if configured_key.present? &&
                  ActiveSupport::SecurityUtils.secure_compare(request.headers['X-API-Key'].to_s, configured_key)

        raise Unauthorized
      end

      def unauthorized
        render json: { error: 'Invalid or missing API key' }, status: :unauthorized
      end
    end
  end
end
