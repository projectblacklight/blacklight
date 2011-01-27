module Blacklight::Routes
  
  # Updated to use Rails3 routing.
  # please see http://guides.rubyonrails.org/routing.html for more information.

  def self.build 
    
    Rails.application.routes.draw do

      # Login, Logout, UserSessions
      # rails2: map.resources :user_sessions, :protocol => ((defined?(SSL_ENABLED) and SSL_ENABLED) ? 'https' : 'http')
      scope :constraints => { 
        :protocol => ((defined?(SSL_ENABLED) and SSL_ENABLED) ? 'https' : 'http')} do
        resources :user_sessions
      end
      # rails2: map.login "login", :controller => "user_sessions", :action => "new"
      match "login", :to => "user_sessions#new", :as => "login"
      # rails2: map.logout "logout", :controller => "user_sessions", :action => "destroy"
      match "logout", :to => "user_sessions#destroy", :as => "logout"
      
      # Set the default controller:
      # rails2:  map.root :controller => 'catalog', :action=>'index'
      root :to => "catalog#index"
      
      # rails2: map.resources :bookmarks, :collection => {:clear => :delete}
      resources :bookmarks, :collection => {:clear => :delete}
      
      # rails2: map.resource :user
      resource :user
      
      # rails2: map.catalog_facet "catalog/facet/:id", :controller=>'catalog', :action=>'facet'
      match 'catalog/facet/#id', :to => "catalog#facet"

      
      # rails2: map.resources :search_history, :collection => {:clear => :delete}
      #        map.resources :saved_searches, :collection => {:clear => :delete}, :member => {:save => :put}
      resources :search_history do
        delete 'clear', :on => :collection      
      end
      resources :saved_searches do
        delete 'clear', :on => :collection 
        put    'save', :on => :member
      end

      resources :catalog, :only => [:index, :show, :update] do
        get 'image',          :on => :member
        get 'status',         :on => :member
        get 'availability',   :on => :member
        get 'librarian_view', :on => :member
        get 'map',               :on => :collection
        get 'opensearch',        :on => :collection
        get 'citation',          :on => :collection
        get 'email',             :on => :collection
        get 'sms',               :on => :collection
        get 'endnote',           :on => :collection
        get 'send_email_record', :on => :collection
      end
      
      #    map.resources(:catalog,
      # /catalog/:id/image <- for ajax cover requests
      # /catalog/:id/status
      # /catalog/:id/availability
      #      :member=>{:image=>:get, :status=>:get, :availability=>:get, :librarian_view=>:get},
      # /catalog/map
      #  :collection => {:map => :get, :opensearch=>:get, :citation=>:get, :email=>:get, :sms=>:get, :endnote=>:get, :send_email_record=>:post}
      # )
      
      # rails2: map.feedback 'feedback', :controller=>'feedback', :action=>'show'
      match "feedback", :to => "feedback#show"

      # rails2: map.feedback_complete 'feedback/complete', :controller=>'feedback', :action=>'complete'
      match "feedback/complete", :to => "feedback#complete"

      # rails2: map.resources :folder, :only => [:index, :create, :destroy], :collection => {:clear => :delete }
      resources :folder, :only => [:index, :create, :destroy] do
        delete  "clear", :on => :collection
      end
      
    end
  end
end
