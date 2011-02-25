# lib/blacklight/engine.rb
require "blacklight"
require "rails"

module Blackight
  class Engine < Rails::Engine

    initializer 'blacklight.helpers' do |app|
      ActionView::Base.send :include, BlacklightHelper
    end

    rake_tasks do
      load "railties/blacklight.rake"
      load "railties/solr_marc.rake"
    end

  end




end
