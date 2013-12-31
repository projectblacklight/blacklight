# -*- encoding : utf-8 -*-
require 'deprecation'
module Blacklight
  class Routes
    extend Deprecation

    attr_reader :resources 

    def initialize(router, options)
      @router = router
      @options = options
      @resources = options.fetch(:resources, [:catalog])
    end

    def draw
      route_sets.each do |r|
        self.send(r, primary_resource)
      end
      resources.each do |r|
        self.map_resource(r)
      end
    end

    protected

    def primary_resource
      resources.first
    end

    def add_routes &blk
      @router.instance_exec(@options, &blk)
    end

    def route_sets
      (@options[:only] || default_route_sets) - (@options[:except] || [])
    end

    def default_route_sets
      # Order is important here.  (e.g. /catalog/email precedes /catalog/:id)
      [:bookmarks, :search_history, :export, :solr_document, :feedback]
    end

    module RouteSets
      def bookmarks(_)
        add_routes do |options|
          delete "bookmarks/clear", :to => "bookmarks#clear", :as => "clear_bookmarks"
          resources :bookmarks
        end
      end
  
      def search_history(_)
        add_routes do |options|
          get "search_history",             :to => "search_history#index",   :as => "search_history"
          delete "search_history/clear",       :to => "search_history#clear",   :as => "clear_search_history"          
        end
      end
  
      def catalog(_=nil)
        Deprecation.warn(Blacklight::Routes, "Blacklight::Routes.catalog is deprecated and will be removed in Blacklight 6.0.  Use Blacklight::Routes.map_resource(:catalog) instead.")
        map_resource(:catalog)
      end

      def map_resource(key)
        add_routes do |options|
          get "#{key}/facet/:id", :to => "#{key}#facet", :as => "#{key}_facet"
          get "#{key}", :to => "#{key}#index", :as => "#{key}_index"
        end
      end

      def export(primary_resource)
        add_routes do |options|
          get "#{primary_resource}/opensearch", :as => "opensearch_#{primary_resource}"
          get "#{primary_resource}/citation", :as => "citation_#{primary_resource}"
          get "#{primary_resource}/email", :as => "email_#{primary_resource}"
          post "#{primary_resource}/email"
          get "#{primary_resource}/sms", :as => "sms_#{primary_resource}"
          get "#{primary_resource}/endnote", :as => "endnote_#{primary_resource}"
        end
      end

      def solr_document(primary_resource)
        add_routes do |options|

          args = {only: [:show, :update]}
          args[:constraints] = options[:constraints] if options[:constraints]

          resources :solr_document, args.merge(path: primary_resource, controller: primary_resource)

          # :show and :update are for backwards-compatibility with catalog_url named routes
          resources primary_resource, args do
            member do
              get 'librarian_view', :to => "catalog#librarian_view", :as => "librarian_view"
            end
          end
        end
      end
  
    
      # Feedback
      def feedback(_)
        add_routes do |options|
          get "feedback", :to => "feedback#show"    
          get "feedback/complete", :to => "feedback#complete"
        end
      end
    end
    include RouteSets
  end
end
