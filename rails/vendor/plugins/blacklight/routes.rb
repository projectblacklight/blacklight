ActionController::Routing::Routes.draw do |map|
  
  map.resources(:sessions,
    # /sessions/cookies_test
    :collection=>{
      :cookies_test=>:get,
      :logout => :get
    },
    # The SSL_ENABLED can be set in an environment file
    :protocol=>((defined?(SSL_ENABLED) and SSL_ENABLED) ? 'https' : 'http')
  )
  map.logout "logout", :controller => "sessions", :action => "logout"
  
  # Set the default controller:
  map.root :controller => 'home'
  map.resources :bookmarks
  map.resources :users, :has_many=>[:bookmarks]
  
  map.catalog_facet "catalog/facet/:id", :controller=>'catalog', :action=>'facet'
  
  map.resources :search_history, :collection => {:clear => :delete}
  map.resources :saved_searches, :collection => {:clear => :delete}, :member => {:save => :put}
  map.resources(:catalog,
    :only => [:index, :show, :update],
    # /catalog/:id/image <- for ajax cover requests
    # /catalog/:id/status
    # /catalog/:id/availability
    :member=>{:image=>:get, :status=>:get, :availability=>:get, :citation=>:get},
    # /catalog/map
    :collection => {:map => :get, :opensearch=>:get}
  )
  
  map.feedback 'feedback', :controller=>'feedback', :action=>'show'
  map.feedback_complete 'feedback/complete', :controller=>'feedback', :action=>'complete'
  
  # including these routes is currently necessary for _facet.html.erb_spec
  #  to work.  There is a bug with link_to and implicit routes.
  # HOWEVER:  including these routes may interfere with the catalog/show
  #  posting magic.
  # So, they are included here, but commented out.  Uncomment them to run
  #   _facet.html.erb_spec
  # Naomi 2009-04-19
#  map.connect ':controller/:action/:id'
#  map.connect ':controller/:action/:id.:format'
  
end