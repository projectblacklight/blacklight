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
      match "bookmarks/clear", :to => "bookmarks#clear", :as => "clear_bookmarks"
      resources :bookmarks
      
      # rails2: map.resource :user
      resource :user
      
      # rails2: map.catalog_facet "catalog/facet/:id", :controller=>'catalog', :action=>'facet'
      match 'catalog/facet/:id', :to => "catalog#facet"

      
      # rails2: map.resources :search_history, :collection => {:clear => :delete}
      #        map.resources :saved_searches, :collection => {:clear => :delete}, :member => {:save => :put}

      match "search_history/clear", :to => "search_history#clear", :as => "clear_search_history"
      resources :search_history

      resources :saved_searches do
        delete 'clear', :on => :collection 
        put    'save', :on => :member
      end

      # Catalog stuff.
      match 'catalog/:id/image', :to => "catalog#image"
      match 'catalog/:id/status', :to => "catalog#status"
      match 'catalog/:id/availability', :to => "catalog#availability"
      match 'catalog/:id/librarian_view', :to => "catalog#librarian_view", :as => "librarian_view_catalog"
      match 'catalog/map', :as => "map_catalog"
      match 'catalog/opensearch', :as => "opensearch_catalog"
      match 'catalog/citation', :as => "citation_catalog"
      match 'catalog/email', :as => "email_catalog"
      match 'catalog/sms', :as => "sms_catalog"
      match 'catalog/endnote', :as => "endnote_catalog"
      match 'catalog/send_email_record', :as => "send_email_record_catalog"
      resources :catalog, :only => [:index, :show, :update], :path => 'catalog'
            
      # rails2: map.feedback 'feedback', :controller=>'feedback', :action=>'show'
      match "feedback", :to => "feedback#show"

      # rails2: map.feedback_complete 'feedback/complete', :controller=>'feedback', :action=>'complete'
      match "feedback/complete", :to => "feedback#complete"

      # rails2: map.resources :folder, :only => [:index, :create, :destroy], :collection => {:clear => :delete }
      match  "folder/clear", :as => "clear_folder"
      resources :folder, :only => [:index, :create, :destroy]       
    end
  end
end
