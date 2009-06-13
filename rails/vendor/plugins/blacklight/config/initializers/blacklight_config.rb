# You can configure Blacklight from here. 
#   
#   Blacklight.configure(:environment) do |config| end
#   
# :shared (or leave it blank) is used by all environments. 
# You can override a shared key by using that key in a particular
# environment's configuration.
# 
# If you have no configuration beyond :shared for an environment, you
# do not need to call configure() for that envirnoment.
# 
# For specific environments:
# 
#   Blacklight.configure(:test) {}
#   Blacklight.configure(:development) {}
#   Blacklight.configure(:production) {}
# 

Blacklight.configure(:shared) do |config|
  
  SolrDocument.marc_source_field  = :marc_display
  SolrDocument.marc_format_type   = :marcxml
  SolrDocument.ead_source_field   = :xml_display
  
  # default params for the SolrDocument.search method
  SolrDocument.default_params[:search] = {
    :qt=>:search,
    :per_page => 10,
    :facets => {:fields=>
      ["language_facet",
      "subject_era_facet",
      "geographic_subject_facet",
      "format_facet"]
    }
  }
  
  # default params for the SolrDocument.find_by_id method
  SolrDocument.default_params[:find_by_id] = {:qt => :document}
  
  
  ##############################
  
  
  config[:default_qt] = "search"
  

  # solr field values given special treatment in the show (single result) view
  config[:show] = {
    :html_title => "title_t",
    :heading => "title_t",
    :display_type => "format_code_t"
  }

  # solr fld values given special treatment in the index (search results) view
  config[:index] = {
    :show_link => "title_t",
    :num_per_page => 10,
    :record_display_type => "format_code_t"
  }

  # solr fields that will be treated as facets by the blacklight application
  #   The ordering of the field names is the order of the display 
  config[:facet] = {
    :field_names => [
      "language_facet",
      "subject_era_facet",
      "geographic_subject_facet",
      "format_facet"
    ],
    :labels => {
      "language_facet"           => "Language",
      "subject_era_facet"        => "Subject - Era",
      "geographic_subject_facet" => "Subject - Geographic",
      "format_facet"             => "Format"
    }
  }

  # solr fields to be displayed in the index (search results) view
  #   The ordering of the field names is the order of the display 
  config[:index_fields] = {
    :field_names => [
      "title_t",
      "author_t",
      "format_facet",
      "language_facet",
      "published_t"
    ],
    :labels => {
      "title_t"        => "Title:",
      "author_t"       => "Author:",
      "format_facet"   => "Format:",
      "language_facet" => "Language:",
      "published_t"    => "Published:"
    }
  }

  # solr fields to be displayed in the show (single result) view
  #   The ordering of the field names is the order of the display 
  config[:show_fields] = {
    :field_names => [
      "title_t",
      "sub_title_t",
      "author_t",
      "format_facet",
      "material_type_t",
      "language_facet",
      "published_t",
      "isbn_t"
    ],
    :labels => {
      "title_t"         => "Title:",
      "sub_title_t"     => "Subtitle:",
      "author_t"        => "Author:",
      "format_facet"    => "Format:",
      "material_type_t" => "Physical description:",
      "language_facet"  => "Language:",
      "published_t"     => "Published:",
      "isbn_t"          => "ISBN:"      
    }
  }

  # type of raw data in index.  Currently marcxml and marc21 are supported.
  config[:raw_storage_type] = "marcxml"
  # name of solr field containing raw data
  config[:raw_storage_field] = "marc_display"

  # "fielded" search select (pulldown)
  # label in pulldown is followed by the name of a SOLR request handler as 
  # defined in solr/conf/solrconfig.xml
  config[:search_fields] ||= []
  config[:search_fields] << ['All Fields', 'search']
  config[:search_fields] << ['Author', 'author_search']
  config[:search_fields] << ['Title', 'title_search']
  
  # "sort results by" select (pulldown)
  # label in pulldown is followed by the name of the SOLR field to sort by and
  # whether the sort is ascending or descending (it must be asc or desc
  # except in the relevancy case).
  # label is key, solr field is value
  config[:sort_fields] ||= []
  config[:sort_fields] << ['relevance', '']
  config[:sort_fields] << ['title', 'title_sort asc']
  config[:sort_fields] << ['format', 'format_sort asc']
  
  # the maximum number of search results to allow display of a spelling 
  #  ("did you mean") suggestion, if one is available.
  config[:spell_max] = 5
end

