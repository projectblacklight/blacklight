class CatalogController < ApplicationController
  
  include Blacklight::SolrHelper
  
  # get search results from the solr index
  def index
    @response = get_search_results(params[:q], params[:f], params[:per_page], params[:page])
    
    session[:search] ||= {}
    # we want to remove the key if the value is blank or nil
    params[:q].blank? ? session[:search].delete(:q) : session[:search][:q] = params[:q]
    params[:f].blank? ? session[:search].delete(:f) : session[:search][:f] = params[:f]
    params[:per_page].blank? ? session[:search].delete(:per_page) : session[:search][:per_page] = params[:per_page]
    params[:page].blank? ? session[:search].delete(:page) : session[:search][:page] = params[:page]
    
    logger.debug("***** session.inspect: #{session.inspect}")
    respond_to do |format|
      format.html{}
      format.rss do
        render :layout=>false
      end
    end  
  end
  
  # get single document from the solr index
  def show
    respond_to do |format|
      format.html do
        # this strips the counter when we don't want it, ie when there is no search
        redirect_to(:action => "show", :id => params[:id]) if session[:search].blank? && params[:counter]

        # this cleans out the search criteria when we're coming from a copy/paste URL without counter
        # because we don't want the context of whatever search we were in
        session[:search] = {} unless params[:counter]

        @response = get_solr_response_for_doc_id(params[:id])
        @document = SolrDocument.new(@response.docs.first)

        setup_previous_document
        setup_next_document
      end
      format.xml do
        @response = get_solr_response_for_doc_id(params[:id])
        @document = SolrDocument.new(@response.docs.first)
        render :xml => @document.to_xml
      end
    end

  end
  
  # displays values and pagination links for a single facet field
  def facet
    @pagination = get_facet_pagination(params[:id])
  end
  
  # single document image resource
  def image
  end
  
  # single document availability status (true/false)
  def status
  end
  
  # single document availability info
  def availability
  end
  
  # collection/search UI via Google maps
  def map
  end
  
  protected
  
  # gets a document based on its position within a resultset  
  def setup_document_by_counter(counter)
    logger.debug("***** session[:search]: #{session[:search].inspect}")
    return if counter < 1 || session[:search].blank?
    search = session[:search] || {}
    get_single_doc_via_search(search[:q], counter, search[:f])
  end
  
  def setup_previous_document
    @previous_document = setup_document_by_counter(params[:counter].to_i - 1)
    logger.debug("***** #{@previous_document.inspect}")
  end
  
  def setup_next_document
    @next_document = setup_document_by_counter(params[:counter].to_i + 1)
  end
  
end