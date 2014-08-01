# -*- encoding : utf-8 -*-
module Blacklight::Catalog   
  extend ActiveSupport::Concern
  
  include Blacklight::Base

  SearchHistoryWindow = 100 # how many searches to save in session history

  # The following code is executed when someone includes blacklight::catalog in their
  # own controller.
  included do
    helper_method :sms_mappings, :has_search_parameters?

    # Whenever an action raises SolrHelper::InvalidSolrID, this block gets executed.
    # Hint: the SolrHelper #get_solr_response_for_doc_id method raises this error,
    # which is used in the #show action here.
    rescue_from Blacklight::Exceptions::InvalidSolrID, :with => :invalid_solr_id_error

    record_search_parameters
  end
  
    # get search results from the solr index
    def index
      (@response, @document_list) = get_search_results
      
      respond_to do |format|
        format.html { }
        format.rss  { render :layout => false }
        format.atom { render :layout => false }
        format.json do
          render json: render_search_results_as_json
        end

        additional_response_formats(format)
        document_export_formats(format)
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
    def track
      search_session['counter'] = params[:counter]
      search_session['per_page'] = params[:per_page]

      path = if params[:redirect] and (params[:redirect].starts_with?("/") or params[:redirect] =~ URI::regexp)
        URI.parse(params[:redirect]).path
      else
        { action: 'show' }
      end
      redirect_to path, :status => 303
    end

    # displays values and pagination links for a single facet field
    def facet
      @facet = blacklight_config.facet_fields[params[:id]]
      @response = get_facet_field_response(@facet.field, params)
      @display_facet = @response.facets.first

      # @pagination was deprecated in Blacklight 5.1
      @pagination = facet_paginator(@facet, @display_facet)


      respond_to do |format|
        # Draw the facet selector for users who have javascript disabled:
        format.html 
        format.json { render json: render_facet_list_as_json }

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
      @response, @documents = get_solr_response_for_document_ids(params[:id])
      respond_to do |format|
        format.html
        format.js { render :layout => false }
      end
    end

    
    # Email Action (this will render the appropriate view on GET requests and process the form and send the email on POST requests)
    def email
      @response, @documents = get_solr_response_for_document_ids(params[:id])
      
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
      @response, @documents = get_solr_response_for_document_ids(params[:id])
      
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

    ##
    # Check if any search parameters have been set
    # @return [Boolean] 
    def has_search_parameters?
      !params[:q].blank? or !params[:f].blank? or !params[:search_field].blank?
    end
    
    protected    
    #
    # non-routable methods ->
    #

    ##
    # Render additional response formats, as provided by the blacklight configuration
    def additional_response_formats format
      blacklight_config.index.respond_to.each do |key, config|
        format.send key do
          case config
          when false
            raise ActionController::RoutingError.new('Not Found')
          when Hash
            render config
          when Proc
            instance_exec &config
          when Symbol, String
            send config
          else
            # no-op, just render the page
          end
        end
      end
    end

    ##
    # Try to render a response from the document export formats available
    def document_export_formats format
      format.any do
        format_name = params.fetch(:format, '').to_sym

        if @response.export_formats.include? format_name
          render_document_export_format format_name
        else
          raise ActionController::UnknownFormat.new
        end
      end
    end

    ##
    # Render the document export formats for a response
    # First, try to render an appropriate template (e.g. index.endnote.erb)
    # If that fails, just concatenate the document export responses with a newline. 
    def render_document_export_format format_name
      begin
        render
      rescue ActionView::MissingTemplate
        render text: @response.documents.map { |x| x.export_as(format_name) if x.exports_as? format_name }.compact.join("\n"), layout: false
      end    
    end

    # override this method to change the JSON response from #index 
    def render_search_results_as_json
      {response: {docs: @document_list, facets: search_facets_as_json, pages: pagination_info(@response)}}
    end

    def search_facets_as_json
      facets_from_request.as_json.each do |f|
        f.delete "options"
        f["label"] = facet_configuration_for_field(f["name"]).label
        f["items"] = f["items"].as_json.each do |i|
          i['label'] ||= i['value']
        end
      end 
    end

    # override this method to change the JSON response from #facet 
    def render_facet_list_as_json
      {response: {facets: @pagination }}
    end

    # Overrides the Blacklight::Controller provided #search_action_url.
    # By default, any search action from a Blacklight::Catalog controller
    # should use the current controller when constructing the route.
    def search_action_url options = {}
      url_for(options.merge(:action => 'index'))
    end

    def url_for(options = nil)
      array_params= []       
      case options
      when nil
        _routes.url_for(url_options.symbolize_keys)
      when Hash 
        if(!options.nil? and !options[:f].nil?)
          options[:f].each do|key,value|
            array_params << "f[#{CGI.escape(key)}][]=#{CGI.escape(value.first)}"
	      end
          options.each do|key,value|
            array_params << "#{CGI.escape(key)}=#{CGI.escape(value)}" if (key != "f" and key != "action" and key != "only_path")  
	      end	      
		end 
		   
		if(!options.nil? and !options[:f].nil?)
		  "#{catalog_index_url}?#{array_params.join('&')}"
		else
		  _routes.url_for(options.symbolize_keys.reverse_merge!(url_options))
		end 
      when String
        options
      else         
        polymorphic_url(options)
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

    # when a request for /catalog/BAD_SOLR_ID is made, this method is executed.
    # Just returns a 404 response, but you can override locally in your own
    # CatalogController to do something else -- older BL displayed a Catalog#inde
    # page with a flash message and a 404 status.
    def invalid_solr_id_error(exception)
      error_info = {
        "status" => "404",
        "error"  => "#{exception.class}: #{exception.message}"
      }

      respond_to do |format|
        format.xml  { render :xml  => error_info, :status => 404 }
        format.json { render :json => error_info, :status => 404 }

        # default to HTML response, even for other non-HTML formats we don't
        # neccesarily know about, seems to be consistent with what Rails4 does
        # by default with uncaught ActiveRecord::RecordNotFound in production
        format.any do
          # use standard, possibly locally overridden, 404.html file. Even for
          # possibly non-html formats, this is consistent with what Rails does
          # on raising an ActiveRecord::RecordNotFound. Rails.root IS needed
          # for it to work under testing, without worrying about CWD.
          render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false, :content_type => 'text/html'
        end
      end
    end

    def start_new_search_session?
      action_name == "index"
    end
end
