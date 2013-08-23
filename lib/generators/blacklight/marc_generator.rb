require 'rails/generators'

module Blacklight
  class MarcGenerator < Rails::Generators::Base

    source_root File.expand_path('../templates', __FILE__)

    desc """
     1. Adds additional mime types to you application in the file '/config/initializers/mime_types.rb'
     2. Creates config/SolrMarc/... with settings for SolrMarc
     3. Creates a CatalogController with some some demo fields for MARC-like data
     4. Injects MARC-specific behaviors into the SolrDocument
    """

    # Content types used by Marc Document extension, possibly among others.
    # Registering a unique content type with 'register' (rather than
    # register_alias) will allow content-negotiation for the format. 
    def add_mime_types
      puts "Updating Mime Types"
      insert_into_file "config/initializers/mime_types.rb", :after => "# Be sure to restart your server when you modify this file." do <<EOF
Mime::Type.register_alias "text/plain", :refworks_marc_txt
Mime::Type.register_alias "text/plain", :openurl_kev
Mime::Type.register "application/x-endnote-refer", :endnote
Mime::Type.register "application/marc", :marc
Mime::Type.register "application/marcxml+xml", :marcxml, 
      ["application/x-marc+xml", "application/x-marcxml+xml", 
       "application/marc+xml"]
EOF
      end
    end 
    
    # Copy all files in templates/config directory to host config
    def create_configuration_files
      directory("config/SolrMarc")
    end

    # Generate blacklight catalog controller
    def create_blacklight_catalog
      copy_file "catalog_controller.rb", "app/controllers/catalog_controller.rb"
    end   

    # add MARC-specific extensions to the solr document
    def add_marc_extension_to_solrdocument

      insert_into_file "app/models/solr_document.rb", :after => "include Blacklight::Solr::Document" do <<EOF
    
      # The following shows how to setup this blacklight document to display marc documents
  extension_parameters[:marc_source_field] = :marc_display
  extension_parameters[:marc_format_type] = :marcxml
  use_extension( Blacklight::Solr::Document::Marc) do |document|
    document.key?( :marc_display  )
  end
  
  field_semantics.merge!(    
                         :title => "title_display",
                         :author => "author_display",
                         :language => "language_facet",
                         :format => "format"
                         )

EOF
      end
    end

  end
end