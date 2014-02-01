# -*- encoding : utf-8 -*-
require 'deprecation'
module Blacklight
  class Routes
    extend Deprecation

    attr_reader :resources 

    # adds as class and instance level accessors, default_route_sets
    # returns an array of symbols for method names that define routes. 
    # Order is important:.  (e.g. /catalog/email precedes /catalog/:id)
    #
    # Add-ons that want to add routes into default routing might
    # monkey-patch Blacklight::Routes, say:
    #
    #     module MyWidget::Routes
    #       extend ActiveSupport::Concern
    #       included do |klass|
    #         klass.default_route_sets += [:widget_routing]
    #       end
    #       def widget_routing(primary_resource)
    #         get "#{primary_resource}/widget", "#{primary_resource}#widget"
    #       end
    #     end
    #     Blacklight::Routes.send(:include, MyWidget::Routes)
    class_attribute :default_route_sets
    self.default_route_sets = [:bookmarks, :search_history, :saved_searches, :export, :solr_document]

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
  
  
      def saved_searches(_)
        add_routes do |options|
          delete "saved_searches/clear",       :to => "saved_searches#clear",   :as => "clear_saved_searches"
          get "saved_searches",       :to => "saved_searches#index",   :as => "saved_searches"
          put "saved_searches/save/:id",    :to => "saved_searches#save",    :as => "save_search"
          delete "saved_searches/forget/:id",  :to => "saved_searches#forget",  :as => "forget_search"
          post "saved_searches/forget/:id",  :to => "saved_searches#forget"
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
        end
      end

      def solr_document(primary_resource)
        add_routes do |options|

          args = {only: [:show, :update]}
          args[:constraints] = options[:constraints] if options[:constraints]

          resources :solr_document, args.merge(path: primary_resource, controller: primary_resource)

          # :show and :update are for backwards-compatibility with catalog_url named routes
          resources primary_resource, args
        end
      end
    end
    include RouteSets
  end
end
