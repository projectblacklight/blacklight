Rails.application.routes.draw do
  
  # Root context
  root :to => "catalog#index"

  # A Note on User Sessions:
  # Blacklight expects the following named routes or at least the associated path helper methods to be defined.
  # new_user_session   (for logging in) - pages that require a log in will redirect users here.
  # destroy_user_session (for logging out)

  
  # Bookmarks 
  match "bookmarks/clear", :to => "bookmarks#clear", :as => "clear_bookmarks"
  resources :bookmarks
  
  # Folder Paths
  match "folder/clear", :to => "folder#clear", :as => "clear_folder"
  match "folder/destroy", :to => "folder#destroy"
  resources :folder, :only => [:index, :update, :destroy] 
  
  # Search History
  match "search_history",             :to => "search_history#index",   :as => "search_history"
  match "search_history/clear",       :to => "search_history#clear",   :as => "clear_search_history"
  match "search_history/destroy/:id", :to => "search_history#destroy", :as => "delete_search"

  # Saved Searches
  match "saved_searches/clear",       :to => "saved_searches#clear",   :as => "clear_saved_searches"
  match "saved_searches/index",       :to => "saved_searches#index",   :as => "saved_searches"
  match "saved_searches/save/:id",    :to => "saved_searches#save",    :as => "save_search"
  match "saved_searches/forget/:id",  :to => "saved_searches#forget",  :as => "forget_search"
  
  # Catalog stuff.
  match 'catalog/map', :as => "map_catalog"
  match 'catalog/opensearch', :as => "opensearch_catalog"
  match 'catalog/citation', :as => "citation_catalog"
  match 'catalog/email', :as => "email_catalog"
  match 'catalog/sms', :as => "sms_catalog"
  match 'catalog/endnote', :as => "endnote_catalog"
  match 'catalog/send_email_record', :as => "send_email_record_catalog"
  match "catalog/facet/:id", :to => 'catalog#facet', :as => 'catalog_facet'
  resources :catalog, :only => [:index, :show, :update]
  match 'catalog/:id/image', :to => "catalog#image"
  match 'catalog/:id/status', :to => "catalog#status"
  match 'catalog/:id/availability', :to => "catalog#availability"
  match 'catalog/:id/librarian_view', :to => "catalog#librarian_view", :as => "librarian_view_catalog"

  
  # Feedback
  match "feedback", :to => "feedback#show"    
  match "feedback/complete", :to => "feedback#complete"
  
end

