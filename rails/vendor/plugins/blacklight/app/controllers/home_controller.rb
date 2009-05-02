class HomeController < ApplicationController
  
  include Blacklight::SolrHelper
  helper CatalogHelper
  
  def index
    if params[:f]
      redirect_to :controller=>'catalog', :f => params[:f]
    end
    @response = get_search_results
  end
  
end