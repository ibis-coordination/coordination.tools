Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root "home#show"
  resource :session, only: %i[new create destroy]
  get "session/confirm", to: "sessions#confirm", as: :confirm_session
  resource :account, only: %i[edit update]
  get "carpool", to: "carpools#new", as: :new_carpool
  resources :carpools, path: "carpool", only: %i[create show edit update destroy], param: :public_id do
    resources :pickups, only: :create
    resources :rides, only: %i[create edit update destroy] do
      resources :ride_claims, only: %i[create destroy], path: "claims"
    end
  end
end
