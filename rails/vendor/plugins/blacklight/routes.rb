ActionController::Routing::Routes.draw do |map|
  
  map.resources(:sessions,
    # /sessions/cookies_test
    :collection=>{
      :cookies_test=>:get
    },
    # The SSL_ENABLED can be set in an environment file
    :protocol=>((defined?(SSL_ENABLED) and SSL_ENABLED) ? 'https' : 'http')
  )
  
  # Set the default controller:
  map.root :controller => 'home'
  
  map.resources :bookmarks
  map.resources :users, :has_many=>[:bookmarks]
  
  map.catalog_facet "catalog/facet/:id", :controller=>'catalog', :action=>'facet'
  
  map.resources(:catalog,
    # /catalog/:id/image <- for ajax cover requests
    # /catalog/:id/status
    # /catalog/:id/availability
    :member=>{:image=>:get, :status=>:get, :availability=>:get},
    # /catalog/map
    :collection=>{:map=>:get}
  )
  
  map.feedback 'feedback', :controller=>'feedback', :action=>'show'
  map.feedback_complete 'feedback/complete', :controller=>'feedback', :action=>'complete'
  
end