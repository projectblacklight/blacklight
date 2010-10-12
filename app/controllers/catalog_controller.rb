class CatalogController < ApplicationController

  include Blacklight::SolrHelper

  before_filter :search_session, :history_session
  before_filter :delete_or_assign_search_session_params,  :only=>:index
  before_filter :adjust_for_results_view, :only=>:update
  after_filter :set_additional_search_session_values, :only=>:index
  
  # Whenever an action raises SolrHelper::InvalidSolrID, this block gets executed.
  # Hint: the SolrHelper #get_solr_response_for_doc_id method raises this error,
  # which is used in the #show action here.
  rescue_from InvalidSolrID, :with => :invalid_solr_id_error

  
  # When RSolr::RequestError is raised, the rsolr_request_error method is executed.
  # The index action will more than likely throw this one.
  # Example, when the standard query parser is used, and a user submits a "bad" query.
  rescue_from RSolr::RequestError, :with => :rsolr_request_error
  
  # get search results from the solr index
  def index

    extra_head_content << '<link rel="alternate" type="application/rss+xml" title="RSS for results" href="'+ url_for(params.merge("format" => "rss")) + '">'
    extra_head_content << '<link rel="alternate" type="application/atom+xml" title="Atom for results" href="'+ url_for(params.merge("format" => "atom")) + '">'
    
    (@response, @document_list) = get_search_results
    @filters = params[:f] || []
    respond_to do |format|
      format.html { save_current_search_params }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
    end
  end
  
  # get single document from the solr index
  def show
    @response, @document = get_solr_response_for_doc_id    
    respond_to do |format|
      format.html {setup_next_and_previous_documents}
      
      # Add all dynamically added (such as by document extensions)
      # export formats.
      @document.export_formats.each_key do | format_name |
        # It's important that the argument to send be a symbol;
        # if it's a string, it makes Rails unhappy for unclear reasons. 
        format.send(format_name.to_sym) { render :text => @document.export_as(format_name) }
      end
      
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
    @response, @documents = get_solr_response_for_field_values("id",params[:id])
  end
  # Email Action (this will only be accessed when the Email link is clicked by a non javascript browser)
  def email
    @response, @documents = get_solr_response_for_field_values("id",params[:id])
  end
  # SMS action (this will only be accessed when the SMS link is clicked by a non javascript browser)
  def sms 
    @response, @documents = get_solr_response_for_field_values("id",params[:id])
  end
  # grabs a bunch of documents to export to endnote
  def endnote
    @response, @documents = get_solr_response_for_field_values("id",params[:id])
    respond_to do |format|
      format.endnote
    end
  end
  
  def librarian_view
    @response, @document = get_solr_response_for_doc_id
  end
  
  # action for sending email.  This is meant to post from the form and to do processing
  def send_email_record
    @response, @documents = get_solr_response_for_field_values("id",params[:id])
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
              email = RecordMailer.create_sms_record(@documents, {:to => params[:to], :carrier => params[:carrier]}, from, host)
            end
          else
            flash[:error] = "You must select a carrier"
          end
        when 'email'
          if params[:to].match(/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
            email = RecordMailer.create_email_record(@documents, {:to => params[:to], :message => params[:message]}, from, host)
          else
            flash[:error] = "You must enter a valid email address"
          end
      end
      RecordMailer.deliver(email) unless flash[:error]
      if @documents.size == 1
        redirect_to catalog_path(@documents.first[:id])
      else
        redirect_to folder_index_path
      end
    else
      flash[:error] = "You must enter a recipient in order to send this message"
    end
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
    @searches = searches_from_history # <- in ApplicationController
  end
  
  # This method copies request params to session[:search], omitting certain
  # known blacklisted params not part of search, omitting keys with blank
  # values. All keys in session[:search] are as symbols rather than strings. 
  def delete_or_assign_search_session_params
    session[:search] = {}
    params.each_pair do |key, value|
      session[:search][key.to_sym] = value unless ["commit", "counter"].include?(key.to_s) ||
      value.blank?
    end
  end
  
  # Saves the current search (if it does not already exist) as a models/search object
  # then adds the id of the serach object to session[:history]
  def save_current_search_params    
    # If it's got anything other than controller, action, total, we
    # consider it an actual search to be saved. Can't predict exactly
    # what the keys for a search will be, due to possible extra plugins. 
    return if (search_session.keys - [:controller, :action, :total, :counter, :commit ]) == [] 
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
  
  # we need to know if we are viewing the item as part of search results so we know whether to
  # include certain partials or not
  def adjust_for_results_view
    if params[:results_view] == "false"
      session[:search][:results_view] = false
    else
      session[:search][:results_view] = true
    end
  end
  
  
  
  # when solr (RSolr) throws an error (RSolr::RequestError), this method is executed.
  def rsolr_request_error(exception)
    if RAILS_ENV == "development"
      raise exception # Rails own code will catch and give usual Rails error page with stack trace
    else
      flash_notice = "Sorry, I don't understand your search."
      # Set the notice flag if the flash[:notice] is already set to the error that we are setting.
      # This is intended to stop the redirect loop error
      notice = flash[:notice] if flash[:notice] == flash_notice
      unless notice
        flash[:notice] = flash_notice
        redirect_to root_path, :status => 500
      else
        render :template => "public/500.html", :layout => false, :status => 500
      end
    end
  end
  
  # when a request for /catalog/BAD_SOLR_ID is made, this method is executed...
  def invalid_solr_id_error
    if RAILS_ENV == "development"
      render # will give us the stack trace
    else
      flash[:notice] = "Sorry, you have requested a record that doesn't exist."
      redirect_to root_path, :status => 404
    end
    
  end
end