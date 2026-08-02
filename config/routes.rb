Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root "home#show"
  resource :session, only: %i[new create destroy]
  resources :carpools, only: %i[new create show edit update], param: :public_id do
    resources :rides, only: %i[create edit update destroy] do
      resources :ride_claims, only: %i[create destroy], path: "claims"
    end
  end
end
