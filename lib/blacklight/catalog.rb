# -*- encoding : utf-8 -*-
module Blacklight::Catalog   
  extend ActiveSupport::Concern
  
  include Blacklight::Configurable
  include Blacklight::SolrHelper
  
  SearchHistoryWindow = 12 # how many searches to save in session history

  # The following code is executed when someone includes blacklight::catalog in their
  # own controller.
  included do  
    helper_method :search_action_url
    helper_method :sms_mappings
    before_filter :search_session, :history_session
    before_filter :delete_or_assign_search_session_params, :only => :index
    after_filter :set_additional_search_session_values, :only=>:index

    # Whenever an action raises SolrHelper::InvalidSolrID, this block gets executed.
    # Hint: the SolrHelper #get_solr_response_for_doc_id method raises this error,
    # which is used in the #show action here.
    rescue_from Blacklight::Exceptions::InvalidSolrID, :with => :invalid_solr_id_error
    # When RSolr::RequestError is raised, the rsolr_request_error method is executed.
    # The index action will more than likely throw this one.
    # Example, when the standard query parser is used, and a user submits a "bad" query.
    rescue_from RSolr::Error::Http, :with => :rsolr_request_error
  end
  
    # get search results from the solr index
    def index
      
      (@response, @document_list) = get_search_results
      @filters = params[:f] || []
      
      respond_to do |format|
        format.html { 
          extra_head_content << view_context.auto_discovery_link_tag(:rss, url_for(params.merge(:format => 'rss')), :title => t('blacklight.search.rss_feed') )
          extra_head_content << view_context.auto_discovery_link_tag(:atom, url_for(params.merge(:format => 'atom')), :title => t('blacklight.search.atom_feed') )
          save_current_search_params
        }
        format.rss  { render :layout => false }
        format.atom { render :layout => false }

        
        format.json { render json: {response: {docs: @document_list, facets: facets_from_request, pages: pagination_info(@response)}}}
      end
    end
    
    # get single document from the solr index
    def show
      @response, @document = get_solr_response_for_doc_id    

      respond_to do |format|
        format.html {setup_next_and_previous_documents}

        format.json { render json: {response: {document: @document}}}

        # Add all dynamically added (such as by document extensions)
        # export formats.
        @document.export_formats.each_key do | format_name |
          # It's important that the argument to send be a symbol;
          # if it's a string, it makes Rails unhappy for unclear reasons. 
          format.send(format_name.to_sym) { render :text => @document.export_as(format_name), :layout => false }
        end
        
      end
    end

    # updates the search counter (allows the show view to paginate)
    def update
      adjust_for_results_view
      session[:search][:counter] = params[:counter]
      redirect_to :action => "show"
    end
    
    # displays values and pagination links for a single facet field
    def facet
      @pagination = get_facet_pagination(params[:id], params)

      respond_to do |format|
        # Draw the facet selector for users who have javascript disabled:
        format.html 
        format.json { render json: {response: {facets: @pagination }}}

        # Draw the partial for the "more" facet modal window:
        format.js { render :layout => false }
      end
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
      @response, @documents = get_solr_response_for_field_values(SolrDocument.unique_key,params[:id])
      respond_to do |format|
        format.html
        format.js { render :layout => false }
      end
    end
    # grabs a bunch of documents to export to endnote
    def endnote
      @response, @documents = get_solr_response_for_field_values(SolrDocument.unique_key,params[:id])
      respond_to do |format|
        format.endnote { render :layout => false }
      end
    end
    
    # Email Action (this will render the appropriate view on GET requests and process the form and send the email on POST requests)
    def email
      @response, @documents = get_solr_response_for_field_values(SolrDocument.unique_key,params[:id])
      
      if request.post? and validate_email_params
        email = RecordMailer.email_record(@documents, {:to => params[:to], :message => params[:message]}, url_options)
        email.deliver 

        flash[:success] = I18n.t("blacklight.email.success")

        respond_to do |format|
          format.html { redirect_to catalog_path(params['id']) }
          format.js { render 'email_sent' }
        end and return
      end

      respond_to do |format|
        format.html
        format.js { render :layout => false }
      end
    end

    
    # SMS action (this will render the appropriate view on GET requests and process the form and send the email on POST requests)
    def sms 
      @response, @documents = get_solr_response_for_field_values(SolrDocument.unique_key,params[:id])
      
      if request.post? and validate_sms_params
        to = "#{params[:to].gsub(/[^\d]/, '')}@#{sms_mappings[params[:carrier]]}"

        sms = RecordMailer.sms_record(@documents, { :to => to }, url_options)
        sms.deliver

        flash[:success] = I18n.t("blacklight.sms.success")

        respond_to do |format|
          format.html { redirect_to catalog_path(params['id']) }
          format.js { render 'sms_sent' }
        end and return
      end
        
      respond_to do |format|
        format.js { render :layout => false }
        format.html
      end
    end
    
    def librarian_view
      @response, @document = get_solr_response_for_doc_id

      respond_to do |format|
        format.html
        format.js { render :layout => false }
      end
    end
    
    
    protected    
    #
    # non-routable methods ->
    #

    def search_action_url options = {}
      url_for(options.merge(:action => 'index', :only_path => true))
    end


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
      get_single_doc_via_search(counter, search)
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
      @searches = searches_from_history # <- in BlacklightController
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
        # Only keep most recent X searches in history, for performance. 
        # both database (fetching em all), and cookies (session is in cookie)
        session[:history] = session[:history].slice(0, Blacklight::Catalog::SearchHistoryWindow )
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
      
      if Rails.env.development?
        raise exception # Rails own code will catch and give usual Rails error page with stack trace
      else

        flash_notice = I18n.t('blacklight.search.errors.request_error')

        # If there are errors coming from the index page, we want to trap those sensibly

        if flash[:notice] == flash_notice
          logger.error "Cowardly aborting rsolr_request_error exception handling, because we redirected to a page that raises another exception"
          raise exception
        end

        logger.error exception

        flash[:notice] = flash_notice 
        redirect_to root_path
      end
    end

    # extract the pagination info from the response object
    def pagination_info response
      h = {}

      [:current_page, :next_page, :prev_page, :total_pages,
       :limit_value, :offset_value, :total_count,
       :first_page?, :last_page?].each do |k|
        h[k] = response.send(k)
      end

      h
    end
    
    def validate_sms_params
      case
      when params[:to].blank?
        flash[:error] = I18n.t('blacklight.sms.errors.to.blank')
      when params[:carrier].blank?
        flash[:error] = I18n.t('blacklight.sms.errors.carrier.blank')
      when params[:to].gsub(/[^\d]/, '').length != 10
        flash[:error] = I18n.t('blacklight.sms.errors.to.invalid', :to => params[:to])
      when !sms_mappings.values.include?(params[:carrier])
        flash[:error] = I18n.t('blacklight.sms.errors.carrier.invalid')
      end

      flash[:error].blank?
    end

    def sms_mappings
      {'Virgin' => 'vmobl.com',
      'AT&T' => 'txt.att.net',
      'Verizon' => 'vtext.com',
      'Nextel' => 'messaging.nextel.com',
      'Sprint' => 'messaging.sprintpcs.com',
      'T Mobile' => 'tmomail.net',
      'Alltel' => 'message.alltel.com',
      'Cricket' => 'mms.mycricket.com'}
    end

    def validate_email_params
      case
      when params[:to].blank?
        flash[:error] = I18n.t('blacklight.email.errors.to.blank')
      when !params[:to].match(defined?(Devise) ? Devise.email_regexp : /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
        flash[:error] = I18n.t('blacklight.email.errors.to.invalid', :to => params[:to])
      end

      flash[:error].blank?
    end

    # when a request for /catalog/BAD_SOLR_ID is made, this method is executed...
    def invalid_solr_id_error
      flash[:notice] = I18n.t('blacklight.search.errors.invalid_solr_id')
      params.delete(:id)
      index
      render "index", :status => 404
    end

    def blacklight_solr
      @solr ||=  RSolr.connect(blacklight_solr_config)
    end

    def blacklight_solr_config
      Blacklight.solr_config
    end
end
