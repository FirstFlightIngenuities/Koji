Rails.application.routes.draw do
  get 'welcome/index'
  root 'welcome#index'

  resources :players
  resources :paymentserviceproviders
  resources :games, :only => [:create, :update]

  get '/checkemail', to: 'players#check_email'
  get '/checkcellphone', to: 'players#check_cellphone'
  get '/checkdisplayname', to: 'players#check_displayname'
  get '/message', to: 'players#startup_message'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
