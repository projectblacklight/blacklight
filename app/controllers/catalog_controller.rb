class CatalogController < ApplicationController
  
  include Blacklight::SolrHelper
  
  before_filter :search_session, :history_session
  before_filter :delete_or_assign_search_session_params,  :only=>:index
  after_filter :set_additional_search_session_values, :only=>:index
  
  # Whenever an action raises SolrHelper::InvalidSolrID, this block gets executed.
  # Hint: the SolrHelper #get_solr_response_for_doc_id method raises this error,
  # which is used in the #show action here.
  rescue_from InvalidSolrID, :with => lambda {
    # when a request for /catalog/BAD_SOLR_ID is made, this method is executed...
    flash[:notice] = "Sorry, you seem to have encountered an error."
    redirect_to catalog_index_path
  }
  
  # When RSolr::RequestError is raised, this block is executed.
  # The index action will more than likely throw this one.
  # Example, when the standard query parser is used, and a user submits a "bad" query.
  rescue_from RSolr::RequestError, :with => lambda {
    # when solr (RSolr) throws an error (RSolr::RequestError), this method is executed.
    flash[:notice] = "Sorry, I don't understand your search."
    redirect_to catalog_index_path
  }
  
  # get search results from the solr index
  def index
    (@response, @document_list) = get_search_results
    @filters = params[:f] || []
    respond_to do |format|
      format.html { save_current_search_params }
      format.rss  { render :layout => false }
    end
  end
  
  # get single document from the solr index
  def show
    @response, @document = get_solr_response_for_doc_id
    respond_to do |format|
      format.html {setup_next_and_previous_documents}
      format.xml  {render :xml => @document.marc.to_xml}
      format.refworks
      format.endnote
    end
  end
  
  # updates the search counter (allows the show view to paginate)
  def update
    session[:search][:counter] = params[:counter]
    redirect_to :action => "show"
  end
  
  # displays values and pagination links for a single facet field
  def facet
    @pagination = get_facet_pagination(params[:id], params)
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
  
  # method to serve up XML OpenSearch description and JSON autocomplete response
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
    @response, @document = get_solr_response_for_doc_id
  end
  # Email Action (this will only be accessed when the Email link is clicked by a non javascript browser)
  def email
    @response, @document = get_solr_response_for_doc_id
  end
  # SMS action (this will only be accessed when the SMS link is clicked by a non javascript browser)
  def sms 
    @response, @document = get_solr_response_for_doc_id
  end
  
  # action for sending email.  This is meant to post from the form and to do processing
  def send_email_record
    @response, @document = get_solr_response_for_doc_id
    if params[:to]
      from = request.host # host w/o port for From address (from address cannot have port#)
      host = request.host
      host << ":#{request.port}" unless request.port.nil? # host w/ port for linking
      case params[:style]
        when 'sms'
          if !params[:carrier].blank?
            if params[:to].length != 10
              flash[:error] = "You must enter a valid 10 digit phone number"
            else
              email = RecordMailer.create_sms_record(@document, {:to => params[:to], :carrier => params[:carrier]}, from, host)
            end
          else
            flash[:error] = "You must select a carrier"
          end
        when 'email'
          if params[:to].match(/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
            email = RecordMailer.create_email_record(@document, {:to => params[:to], :message => params[:message]}, from, host)
          else
            flash[:error] = "You must enter a valid email address"
          end
      end
      RecordMailer.deliver(email) unless flash[:error]
      redirect_to catalog_path(@document[:id])
    else
      flash[:error] = "You must enter a recipient in order to send this message"
    end
  end

    ##################
  # Config-lookup methods. Should be moved to a module of some kind, once
  # all this stuff is modulized. But methods to look up config'ed values,
  # so logic for lookup is centralized in case storage methods changes.
  # Such methods need to be available from controller and helper sometimes,
  # so they go in controller with helper_method added.
  # TODO: Move to a module, and make them look inside the controller
  # for info instead of in global Blacklight.config object!
  ###################

  # Look up configged facet limit for given facet_field. If no
  # limit is configged, may drop down to default limit (nil key)
  # otherwise, returns nil for no limit config'ed. 
  def facet_limit_for(facet_field)
    limits_hash = facet_limit_hash
    return nil unless limits_hash

    limit = limits_hash[facet_field]
    limit = limits_hash[nil] unless limit

    return limit
  end
  helper_method :facet_limit_for
  # Returns complete hash of key=facet_field, value=limit.
  # Used by SolrHelper#solr_search_params to add limits to solr
  # request for all configured facet limits.
  def facet_limit_hash
    Blacklight.config[:facet][:limits]           
  end
  helper_method :facet_limit_hash
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
    @searches = searches_from_history # <- in ApplicationController
  end
  
  # This method will remove certain params from the session[:search] hash
  # if the values are blank? (nil or empty string)
  # if the values aren't blank, they are saved to the session in the :search hash.
  def delete_or_assign_search_session_params
    [:q, :qt, :search_field, :f, :per_page, :page, :sort].each do |pname|
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
  
  # sets some additional search metadata so that the show view can display it.
  def set_additional_search_session_values
    unless @response.nil?
      search_session[:total] = @response.total
    end
  end


  
end