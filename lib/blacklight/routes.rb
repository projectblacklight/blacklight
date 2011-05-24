module Blacklight
  class Routes

    def initialize(router, options)
      @router = router
      @options = options
    end

    def draw
      route_sets.each do |r|
        self.send(r)
      end
    end

    protected

    def add_routes &blk
      @router.instance_exec(@options, &blk)
    end

    def route_sets
      (@options[:only] || default_route_sets) - (@options[:except] || [])
    end

    def default_route_sets
      [:bookmarks, :folders, :search_history, :saved_searches, :catalog, :feedback]
    end

    module RouteSets
      def bookmarks
        add_routes do |options|
          match "bookmarks/clear", :to => "bookmarks#clear", :as => "clear_bookmarks"
          resources :bookmarks
        end
      end
  
  
      def folders
        add_routes do |options|
           match "folder/clear", :to => "folder#clear", :as => "clear_folder"
          match "folder/destroy", :to => "folder#destroy"
          resources :folder, :only => [:index, :update, :destroy] 
        end
      end
    
      def search_history
        add_routes do |options|
          match "search_history",             :to => "search_history#index",   :as => "search_history"
          match "search_history/clear",       :to => "search_history#clear",   :as => "clear_search_history"
          match "search_history/destroy/:id", :to => "search_history#destroy", :as => "delete_search"
        end
      end
  
  
      def saved_searches
        add_routes do |options|
          match "saved_searches/clear",       :to => "saved_searches#clear",   :as => "clear_saved_searches"
          match "saved_searches",       :to => "saved_searches#index",   :as => "saved_searches"
          match "saved_searches/save/:id",    :to => "saved_searches#save",    :as => "save_search"
          match "saved_searches/forget/:id",  :to => "saved_searches#forget",  :as => "forget_search"
        end
      end
    
      def catalog
        add_routes do |options|
          # Catalog stuff.
          match 'catalog/opensearch', :as => "opensearch_catalog"
          match 'catalog/citation', :as => "citation_catalog"
          match 'catalog/email', :as => "email_catalog"
          match 'catalog/sms', :as => "sms_catalog"
          match 'catalog/endnote', :as => "endnote_catalog"
          match 'catalog/send_email_record', :as => "send_email_record_catalog"
          match "catalog/facet/:id", :to => 'catalog#facet', :as => 'catalog_facet'
          match 'catalog/unapi', :to => "catalog#unapi", :as => 'unapi'
          resources :catalog, :only => [:index, :show, :update]
          match 'catalog/:id/librarian_view', :to => "catalog#librarian_view", :as => "librarian_view_catalog"
        end
      end
  
    
      # Feedback
      def feedback
        add_routes do |options|
          match "feedback", :to => "feedback#show"    
          match "feedback/complete", :to => "feedback#complete"
        end
      end
    end
    include RouteSets
  end
end
