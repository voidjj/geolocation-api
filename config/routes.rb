# frozen_string_literal: true

Rails.application.routes.draw do
  get 'up' => 'rails/health#show', as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :geolocations, only: %i[show create destroy], constraints: { id: %r{[^/]+} }
    end
  end
end
