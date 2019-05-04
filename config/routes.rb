Rails.application.routes.draw do
  root "offices#index"
  get 'search' => 'offices#search'
  resources :offices
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
