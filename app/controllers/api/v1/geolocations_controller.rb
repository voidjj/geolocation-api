# frozen_string_literal: true

module Api
  module V1
    class GeolocationsController < BaseController
      def show
        geolocation = Geolocation.find_by!(host: params[:id]) # rubocop:disable Rails/StrongParametersExpect
        serialized = GeolocationSerializer.new(geolocation).serializable_hash

        render json: serialized, status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Geolocation not found for: #{params[:id]}" }, status: :not_found
      end

      def create
        host = create_params[:host]
        data = GeolocationLookup.call(host)
        geolocation = GeolocationPersister.call(host:, data:)
        serialized = GeolocationSerializer.new(geolocation).serializable_hash

        render json: serialized, status: :created
      rescue GeolocationPersister::Error => e
        render json: { error: e.message }, status: :conflict
      rescue GeolocationLookup::Error => e
        render json: { error: e.message }, status: :unprocessable_content
      end

      def destroy
        geolocation = Geolocation.find_by!(host: params[:id]) # rubocop:disable Rails/StrongParametersExpect
        geolocation.destroy!
        head :no_content
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Geolocation not found for: #{params[:id]}" }, status: :not_found
      rescue ActiveRecord::RecordNotDestroyed => e
        render json: { error: e.message }, status: :unprocessable_content
      end

      private

      def create_params
        params.expect(geolocation: [:host])
      end
    end
  end
end
