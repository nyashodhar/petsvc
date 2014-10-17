Rails.application.routes.draw do

  # DeploymentsController:
  #===============================
  get "/", to: "deployments#status", as: 'status'

  # DevicesController
  #===============================
  post "device", to: "devices#create", as: 'create_device'
  post "device/registration", to: "devices#register_device", as: 'register_device'
  delete "device/registration/:device_id", to: "devices#deregister_device", as: 'deregister_device'

  # PetsController
  #===============================
  post "pet", to: "pets#create_pet", as: 'create_pet'
  put "pet/:pet_id", to: "pets#update_pet", as: 'update_pet'
  get "pet/owned", to: "pets#get_owned_pet_ids_for_logged_in_user", as: 'get_owned_pet_ids_for_logged_in_user'
  get "pet/:pet_id", to: "pets#get_pet", as: "get_pet"

  # ApplicationController:
  #===============================
  match "*path", to: "application#not_found", via: :all

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
