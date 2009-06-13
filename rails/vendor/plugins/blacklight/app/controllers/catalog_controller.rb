class CatalogController < ApplicationController
  
  include Blacklight::SolrHelper
  
  before_filter :search_session, :history_session
  before_filter :delete_or_assign_search_session_params,  :only=>:index
  
  # get search results from the solr index
  def index
    @response = get_search_results
    @filters = params[:f] || []
    respond_to do |format|
      format.html { save_current_search_params }
      format.rss  { render :layout => false }
    end
  end
  
  # updates the search counter (allows the show view to paginate)
  def update
    session[:search][:counter] = params[:counter]
    redirect_to :action => "show"
  end
  
  # get single document from the solr index
  def show
    @response = get_solr_response_for_doc_id
    @document = SolrDocument.new(@response.docs.first)
    respond_to do |format|
      format.html {setup_next_and_previous_documents}
      format.xml  {render :xml => @document.marc.to_xml}
    end
  end
  
  # displays values and pagination links for a single facet field
  def facet
    @pagination = get_facet_pagination
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
  
  # 
  def opensearch
    respond_to do |format|
      format.xml do
        render :layout => false
      end
      format.json do
        render :json => get_opensearch_response
      end
    end
  end
  
  # citation action
  def citation
    @response = get_solr_response_for_doc_id
    @document = SolrDocument.new(@response.docs.first)
  end
  
  protected
  
  #
  # non-routable methods ->
  #
  
  # calls setup_previous_document then setup_next_document.
  # used in the show action for single view pagination.
  def setup_next_and_previous_documents
    setup_previous_document
    setup_next_document
  end
  
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
  
  # sets up the session[:search] hash if it doesn't already exist
  def search_session
    session[:search] ||= {}
  end
  
  # sets up the session[:history] hash if it doesn't already exist.
  # assigns all Search objects (that match the searches in session[:history]) to a variable @searches.
  def history_session
    session[:history] ||= []
    @searches = searches_from_history
  end
  
  # This method will remove certain params from the session[:search] hash
  # if the values are blank? (nil or empty string)
  # if the values aren't blank, they are saved to the session in the :search hash.
  def delete_or_assign_search_session_params
    [:q, :qt, :f, :per_page, :page, :sort].each do |pname|
      params[pname].blank? ? session[:search].delete(pname) : session[:search][pname] = params[pname]
    end
  end
  
  # Saves the current search (if it does not already exist) as a models/search object
  # then adds the id of the serach object to session[:history]
  def save_current_search_params
    return if search_session[:q].blank? && search_session[:f].blank?
    params_copy = search_session.clone # don't think we need a deep copy for this
    params_copy.delete(:page)
    unless @searches.collect { |search| search.query_params }.include?(params_copy)
      new_search = Search.create(:query_params => params_copy)
      session[:history].unshift(new_search.id)
    end
  end
  
end