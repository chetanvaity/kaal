Kaal::Application.routes.draw do
  get "activity_log/index"

  get "users/new"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  root :to => 'timelines#newhomepage'

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  resources :events

  #This is our search function
  #Note: Here we have given 'tlsearch' as alias, so that we can use 
  #tlsearch_path in our code. Later we can change actual route from 'tl' to something else.
  #And there, we do not need to change our code to adjust the calling function.
  # SO ...keep 'tlsearch' as it is even if you change actual route.
  match 'tl' => 'events#query2', :as=> :tlsearch
  match 'search_events' => 'events#search'
  match 'ac_search' => 'tags#ac_search'

  match 'credits' => 'static#credits'
  match 'about' => 'static#about_us'
  match 'faq' => 'static#faq'
  
  match '/auth/:service/callback' => 'sessions#create' 
  match '/auth/failure' => 'sessions#failure'
  
  resources :sessions, only: [ :new, :create, :destroy ]
  match '/signin',  to: 'sessions#new'
  match '/signout', to: 'sessions#destroy', via: :delete
  #
  # This page is used only during redirection.
  match '/extlogin', to: 'sessions#external_sign_in', :as => :extlogin

  match '/my'=> 'users#mycontent'

  resources :activity_log do
    get 'page/:page', :action => :index, :on => :collection
  end

  resources :timelines
  match 'tlhome' => 'timelines#homepage', :as=> :tlhome
  match 'tlnsearch' => 'timelines#search', :as=> :tlnsearch
  match 'showcase' => 'timelines#showcase'
  match 'newtlhome' => 'timelines#newhomepage', :as=> :newtlhome

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
