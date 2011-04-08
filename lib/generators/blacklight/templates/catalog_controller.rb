require 'blacklight/catalog'

class CatalogController < ApplicationController  

  include Blacklight::SolrHelper
  include Blacklight::Catalog

end 
