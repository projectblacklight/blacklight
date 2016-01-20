# frozen_string_literal: true
require 'rails/generators'

module Blacklight
  class DocumentGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path('../templates', __FILE__)

    argument     :model_name, :type => :string , :default => "solr_document"

    desc """
This generator makes the following changes to your application:
 1. Creates a blacklight document in your /app/models directory
"""
    def create_solr_document
      template "solr_document.rb", "app/models/#{model_name}.rb"
    end

  end
end
