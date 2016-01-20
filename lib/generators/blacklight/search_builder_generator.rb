# frozen_string_literal: true
require 'rails/generators'

module Blacklight
  class SearchBuilderGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path('../templates', __FILE__)

    argument     :model_name, :type => :string , :default => "search_builder"

    desc """
This generator makes the following changes to your application:
 1. Creates a blacklight search builder in your /app/models directory
"""
    def create_search_builder
      template "search_builder.rb", "app/models/#{model_name}.rb"
    end

  end
end
