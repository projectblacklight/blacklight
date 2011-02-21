BlacklightApp::Application.routes.draw do

  Rails.application.routes.draw do
    
    # Root context
    root :to => "catalog#index"

    # Login, Logout, UserSessions
    scope :constraints => { 
      :protocol => ((defined?(SSL_ENABLED) and SSL_ENABLED) ? 'https' : 'http')} do
      resources :user_sessions
    end
    match "login", :to => "user_sessions#new", :as => "login"
    match "logout", :to => "user_sessions#destroy", :as => "logout"
    resource :user
    
    # Bookmarks 
    match "bookmarks/clear", :to => "bookmarks#clear", :as => "clear_bookmarks"
    resources :bookmarks
    
    # Folders  (using resource here is a bad idea. since a folder is a singular sort of
    # object and doesn't really behave in the expected way - add to this thyat we are 
    # limiting with the "only" and you get some strange behavior - like the fact that
    # folder_path helper method is created automatically and sets an action of "delete" 
    match "folder/clear", :to => "folder#clear", :as => "clear_folder"
    match "folder/destroy", :to => "folder#destroy"
    resources :folder, :only => [:index, :create, :destroy] 
    
    # Search History
    match "search_history/clear", :to => "search_history#clear", :as => "clear_search_history"
    resources :search_history    
    resources :saved_searches do
      delete 'clear', :on => :collection 
      put    'save', :on => :member
    end
    
    # Catalog stuff.
    match 'catalog/facet/:id', :to => "catalog#facet"
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
    resources :catalog, :only => [:index, :show, :update]
    
    # Feedback
    match "feedback", :to => "feedback#show"    
    match "feedback/complete", :to => "feedback#complete"
    
  end
end

