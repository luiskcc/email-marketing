Rails.application.routes.draw do
  resources :prospects
  devise_for :users

  root "prospects#index"
end
