module Blacklight::Routes
  
  def self.build map
    
    # Login, Logout, UserSessions
    map.resources :user_sessions, :protocol => ((defined?(SSL_ENABLED) and SSL_ENABLED) ? 'https' : 'http')
    map.login "login", :controller => "user_sessions", :action => "new"
    map.logout "logout", :controller => "user_sessions", :action => "destroy"

    # Set the default controller:
    map.root :controller => 'catalog', :action=>'index'
    map.resources :bookmarks, :collection => {:clear => :delete}
    map.resource :user

    map.catalog_facet "catalog/facet/:id", :controller=>'catalog', :action=>'facet'

    map.resources :search_history, :collection => {:clear => :delete}
    map.resources :saved_searches, :collection => {:clear => :delete}, :member => {:save => :put}

    map.unapi "catalog/unapi", :controller => 'catalog', :action => 'unapi'

    map.resources(:catalog,
      :only => [:index, :show, :update],
      # /catalog/:id/image <- for ajax cover requests
      # /catalog/:id/status
      # /catalog/:id/availability
      :member=>{:image=>:get, :status=>:get, :availability=>:get, :librarian_view=>:get},
      # /catalog/map
      :collection => {:map => :get, :opensearch=>:get, :citation=>:get, :email=>:get, :sms=>:get, :endnote=>:get, :send_email_record=>:post}
    )

    

    map.feedback 'feedback', :controller=>'feedback', :action=>'show'
    map.feedback_complete 'feedback/complete', :controller=>'feedback', :action=>'complete'
    
    map.resources :folder, :only => [:index, :update, :destroy], :collection => {:clear => :delete }
    
  end
  
end
