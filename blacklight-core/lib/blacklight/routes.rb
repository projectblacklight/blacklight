# -*- encoding : utf-8 -*-
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
      [:bookmarks, :search_history, :saved_searches, :catalog, :solr_document, :feedback]
    end

    module RouteSets
      def bookmarks
        add_routes do |options|
          delete "bookmarks/clear", :to => "bookmarks#clear", :as => "clear_bookmarks"
          resources :bookmarks
        end
      end
  
      def search_history
        add_routes do |options|
          get "search_history",             :to => "search_history#index",   :as => "search_history"
          delete "search_history/clear",       :to => "search_history#clear",   :as => "clear_search_history"          
        end
      end
  
  
      def saved_searches
        add_routes do |options|
          delete "saved_searches/clear",       :to => "saved_searches#clear",   :as => "clear_saved_searches"
          get "saved_searches",       :to => "saved_searches#index",   :as => "saved_searches"
          put "saved_searches/save/:id",    :to => "saved_searches#save",    :as => "save_search"
          delete "saved_searches/forget/:id",  :to => "saved_searches#forget",  :as => "forget_search"
          post "saved_searches/forget/:id",  :to => "saved_searches#forget"
        end
      end
    
      def catalog
        add_routes do |options|
          # Catalog stuff.
          get 'catalog/opensearch', :as => "opensearch_catalog"
          get 'catalog/citation', :as => "citation_catalog"
          get 'catalog/email', :as => "email_catalog"
          post 'catalog/email'
          get 'catalog/sms', :as => "sms_catalog"
          get 'catalog/endnote', :as => "endnote_catalog"
          get "catalog/facet/:id", :to => 'catalog#facet', :as => 'catalog_facet'


          get "catalog", :to => 'catalog#index', :as => 'catalog_index'

          get 'catalog/:id/librarian_view', :to => "catalog#librarian_view", :as => "librarian_view_catalog"
        end
      end

      def solr_document
        add_routes do |options|
          resources :solr_document,  :path => 'catalog', :controller => 'catalog', :only => [:show, :update] 

          # :show and :update are for backwards-compatibility with catalog_url named routes
          resources :catalog, :only => [:show, :update]
        end
      end
  
    
      # Feedback
      def feedback
        add_routes do |options|
          get "feedback", :to => "feedback#show"    
          get "feedback/complete", :to => "feedback#complete"
        end
      end
    end
    include RouteSets
  end
end
