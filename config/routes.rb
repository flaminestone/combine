Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
   root 'mainpage#index'

  # Example of regular route:
     post 'upload_x2t' => 'mainpage#upload_x2t'
     post 'upload_file' => 'mainpage#upload_file'
     post 'convert_all_by_format' => 'mainpage#convert_all_by_format'
     post '/' => 'mainpage#index'
     get 'result_page' => 'mainpage#result_page'
     get '/get_current_result_number' => 'mainpage#get_current_result_number'
     post '/results' => 'mainpage#get_current_result_number'
     post 'result_page' => 'mainpage#result_page'
     post 'kill_x2t' => 'mainpage#kill_x2t'

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
