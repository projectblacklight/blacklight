class CatalogController < ApplicationController
  
  include Blacklight::SolrHelper
  before_filter :search_session, :history_session
  
  # get search results from the solr index
  def index
    @response = get_search_results(params)
    
    # we want to remove the key if the value is blank or nil
    params[:q].blank? ? session[:search].delete(:q) : session[:search][:q] = params[:q]
    params[:qt].blank? ? session[:search].delete(:qt) : session[:search][:qt] = params[:qt]
    params[:f].blank? ? session[:search].delete(:f) : session[:search][:f] = params[:f]
    params[:per_page].blank? ? session[:search].delete(:per_page) : session[:search][:per_page] = params[:per_page]
    params[:page].blank? ? session[:search].delete(:page) : session[:search][:page] = params[:page]
    params[:sort].blank? ? session[:search].delete(:sort) : session[:search][:sort] = params[:sort]
    
    respond_to do |format|
      format.html do
        params_copy = session[:search].clone # don't think we need a deep copy for this
        params_copy.delete(:page)
        unless @searches.collect { |search| search.query_params }.include?(params_copy)
          new_search = Search.create(:query_params => params_copy)
          session[:history].unshift(new_search.id)
        end
      end
      format.rss do
        render :layout => false
      end
    end  
  end
  
  def update
    session[:search][:counter] = params[:counter]
    redirect_to :action => "show"
  end
  
  # get single document from the solr index
  def show
    respond_to do |format|
      format.html do
        @response = get_solr_response_for_doc_id(params[:id])
        @document = SolrDocument.new(@response.docs.first)

        setup_previous_document
        setup_next_document
      end
      format.xml do
        @response = get_solr_response_for_doc_id(params[:id])
        @document = SolrDocument.new(@response.docs.first)
        render :xml => @document.storage.to_xml
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
  def opensearch
    respond_to do |format|
      format.xml do
        render :layout => false
      end
      format.json do
        args = params ? params.symbolize_keys : {}
        mapper = RSolr::Ext::Request::Standard.new
        solr_params = mapper.map({
          :q => args[:q],
          :qt => Blacklight.config[:default_qt],
          :per_page => 10,
          :fl => Blacklight.config[:index][:show_link]
        })
        raw_response = Blacklight.solr.select(solr_params)
        @response = RSolr::Ext::Response::Standard.new(raw_response).docs
        a = Array.new
        b = Array.new
        a = [args[:q]]
        @response.each do|v|
          b << v[Blacklight.config[:index][:show_link]].to_s
        end
        a << b
        render :json => a
      end
    end
  end
  # citation action
  def citation
    @response = get_solr_response_for_doc_id(params[:id])
    @document = SolrDocument.new(@response.docs.first)
  end
  protected
  
  # gets a document based on its position within a resultset  
  def setup_document_by_counter(counter)
    return if counter < 1 || session[:search].blank?
    search = session[:search] || {}
    get_single_doc_via_search(search.merge({:page => counter}))
  end
  
  def setup_previous_document
    @previous_document = session[:search][:counter] ? setup_document_by_counter(session[:search][:counter].to_i - 1) : nil
  end
  
  def setup_next_document
    @next_document = session[:search][:counter] ? setup_document_by_counter(session[:search][:counter].to_i + 1) : nil
  end
  
  def search_session
    session[:search] ||= {}
  end
  def history_session
    session[:history] ||= []
    @searches = Search.all(session[:history])
  end
end