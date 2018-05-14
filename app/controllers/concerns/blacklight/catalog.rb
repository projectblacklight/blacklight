# frozen_string_literal: true
module Blacklight::Catalog
  extend ActiveSupport::Concern

  include Blacklight::Base
  include Blacklight::Facet

  # The following code is executed when someone includes blacklight::catalog in their
  # own controller.
  included do
    helper_method :sms_mappings, :has_search_parameters?, :facet_limit_for

    helper Blacklight::Facet

    # The index action will more than likely throw this one.
    # Example: when the standard query parser is used, and a user submits a "bad" query.
    rescue_from Blacklight::Exceptions::InvalidRequest, with: :handle_request_error

    record_search_parameters
  end

  # get search results from the solr index
  def index
    (@response, deprecated_document_list) = search_service.search_results

    @document_list = ActiveSupport::Deprecation::DeprecatedObjectProxy.new(deprecated_document_list, 'The @document_list instance variable is deprecated; use @response.documents instead.')

    respond_to do |format|
      format.html { store_preferred_view }
      format.rss  { render layout: false }
      format.atom { render layout: false }
      format.json do
        @presenter = Blacklight::JsonPresenter.new(@response,
                                                   facets_from_request,
                                                   blacklight_config)
      end
      additional_response_formats(format)
      document_export_formats(format)
    end
  end

  # get a single document from the index
  # to add responses for formats other than html or json see _Blacklight::Document::Export_
  def show
    deprecated_response, @document = search_service.fetch(params[:id])
    @response = ActiveSupport::Deprecation::DeprecatedObjectProxy.new(deprecated_response, 'The @response instance variable is deprecated; use @document.response instead.')

    respond_to do |format|
      format.html { @search_context = setup_next_and_previous_documents }
      format.json { render json: { response: { document: @document } } }
      additional_export_formats(@document, format)
    end
  end

  # updates the search counter (allows the show view to paginate)
  def track
    search_session['counter'] = params[:counter]
    search_session['id'] = params[:search_id]
    search_session['per_page'] = params[:per_page]

    if params[:redirect] && (params[:redirect].starts_with?('/') || params[:redirect] =~ URI::DEFAULT_PARSER.make_regexp)
      uri = URI.parse(params[:redirect])
      path = uri.query ? "#{uri.path}?#{uri.query}" : uri.path
      redirect_to path, status: 303
    else
      redirect_to blacklight_config.document_model.new(id: params[:id]), status: 303
    end
  end

  # displays values and pagination links for a single facet field
  def facet
    @facet = blacklight_config.facet_fields[params[:id]]
    raise ActionController::RoutingError, 'Not Found' unless @facet
    @response = search_service.facet_field_response(@facet.key)
    @display_facet = @response.aggregations[@facet.field]
    @pagination = facet_paginator(@facet, @display_facet)
    respond_to do |format|
      format.html do
        # Draw the partial for the "more" facet modal window:
        return render layout: false if request.xhr?
        # Otherwise draw the facet selector for users who have javascript disabled.
      end
      format.json
    end
  end

  # method to serve up XML OpenSearch description and JSON autocomplete response
  def opensearch
    respond_to do |format|
      format.xml { render layout: false }
      format.json { render json: search_service.opensearch_response }
    end
  end

  def suggest
    respond_to do |format|
      format.json do
        render json: suggestions_service.suggestions
      end
    end
  end

  def action_documents
    search_service.fetch(Array(params[:id]))
  end

  def action_success_redirect_path
    search_state.url_for_document(blacklight_config.document_model.new(id: params[:id]))
  end

  ##
  # Check if any search parameters have been set
  # @return [Boolean]
  def has_search_parameters?
    !params[:q].blank? || !params[:f].blank? || !params[:search_field].blank?
  end

  DEFAULT_FACET_LIMIT = 10

  # Look up facet limit for given facet_field. Will look at config, and
  # if config is 'true' will look up from Solr @response if available. If
  # no limit is available, returns nil. Used from #add_facetting_to_solr
  # to supply f.fieldname.facet.limit values in solr request (no @response
  # available), and used in display (with @response available) to create
  # a facet paginator with the right limit.
  def facet_limit_for(facet_field)
    facet = blacklight_config.facet_fields[facet_field]
    return if facet.blank?

    if facet.limit && @response && @response.aggregations[facet.field]
      limit = @response.aggregations[facet.field].limit

      if limit.nil? # we didn't get or a set a limit, so infer one.
        facet.limit if facet.limit != true
      elsif limit == -1 # limit -1 is solr-speak for unlimited
        nil
      else
        limit.to_i - 1 # we added 1 to find out if we needed to paginate
      end
    elsif facet.limit
      facet.limit == true ? DEFAULT_FACET_LIMIT : facet.limit
    end
  end

  private

  #
  # non-routable methods ->
  #

  def render_sms_action?(_config, _options)
    sms_mappings.present?
  end

  def search_service
    search_service_class.new(blacklight_config, search_state.to_h)
  end

  ##
  # If the params specify a view, then store it in the session. If the params
  # do not specifiy the view, set the view parameter to the value stored in the
  # session. This enables a user with a session to do subsequent searches and have
  # them default to the last used view.
  def store_preferred_view
    session[:preferred_view] = params[:view] if params[:view]
  end

  ##
  # Render additional response formats for the index action, as provided by the
  # blacklight configuration
  # @param [Hash] format
  # @note Make sure your format has a well known mime-type or is registered in config/initializers/mime_types.rb
  # @example
  #   config.index.respond_to.txt = Proc.new { render plain: "A list of docs." }
  def additional_response_formats format
    blacklight_config.index.respond_to.each do |key, config|
      format.send key do
        case config
        when false
          raise ActionController::RoutingError, 'Not Found'
        when Hash
          render config
        when Proc
          instance_exec(&config)
        when Symbol, String
          send config
        else
          render({})
        end
      end
    end
  end

  ##
  # Render additional export formats for the show action, as provided by
  # the document extension framework. See _Blacklight::Document::Export_
  def additional_export_formats(document, format)
    document.export_formats.each_key do |format_name|
      format.send(format_name.to_sym) { render body: document.export_as(format_name), layout: false }
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
        raise ActionController::UnknownFormat
      end
    end
  end

  ##
  # Render the document export formats for a response
  # First, try to render an appropriate template (e.g. index.endnote.erb)
  # If that fails, just concatenate the document export responses with a newline.
  def render_document_export_format format_name
    render
  rescue ActionView::MissingTemplate
    render plain: @response.documents.map { |x| x.export_as(format_name) if x.exports_as? format_name }.compact.join("\n"), layout: false
  end

  # Overrides the Blacklight::Controller provided #search_action_url.
  # By default, any search action from a Blacklight::Catalog controller
  # should use the current controller when constructing the route.
  def search_action_url options = {}
    url_for(options.reverse_merge(action: 'index'))
  end

  # Email Action (this will render the appropriate view on GET requests and process the form and send the email on POST requests)
  def email_action documents
    mail = RecordMailer.email_record(documents, { to: params[:to], message: params[:message] }, url_options)
    if mail.respond_to? :deliver_now
      mail.deliver_now
    else
      mail.deliver
    end
  end

  # SMS action (this will render the appropriate view on GET requests and process the form and send the email on POST requests)
  def sms_action documents
    to = "#{params[:to].gsub(/[^\d]/, '')}@#{params[:carrier]}"
    mail = RecordMailer.sms_record(documents, { to: to }, url_options)
    if mail.respond_to? :deliver_now
      mail.deliver_now
    else
      mail.deliver
    end
  end

  def validate_sms_params
    if params[:to].blank?
      flash[:error] = I18n.t('blacklight.sms.errors.to.blank')
    elsif params[:carrier].blank?
      flash[:error] = I18n.t('blacklight.sms.errors.carrier.blank')
    elsif params[:to].gsub(/[^\d]/, '').length != 10
      flash[:error] = I18n.t('blacklight.sms.errors.to.invalid', to: params[:to])
    elsif !sms_mappings.value?(params[:carrier])
      flash[:error] = I18n.t('blacklight.sms.errors.carrier.invalid')
    end

    flash[:error].blank?
  end

  def sms_mappings
    Blacklight::Engine.config.sms_mappings
  end

  def validate_email_params
    if params[:to].blank?
      flash[:error] = I18n.t('blacklight.email.errors.to.blank')
    elsif !params[:to].match(Blacklight::Engine.config.email_regexp)
      flash[:error] = I18n.t('blacklight.email.errors.to.invalid', to: params[:to])
    end

    flash[:error].blank?
  end

  def start_new_search_session?
    action_name == "index"
  end

  def suggestions_service
    Blacklight::SuggestSearch.new(params, search_service.repository).suggestions
  end

  def determine_layout
    action_name == 'show' ? 'catalog_result' : super
  end

  # when a method throws a Blacklight::Exceptions::InvalidRequest, this method is executed.
  def handle_request_error(exception)
    # Rails own code will catch and give usual Rails error page with stack trace
    raise exception if Rails.env.development? || Rails.env.test?

    flash_notice = I18n.t('blacklight.search.errors.request_error')

    # If there are errors coming from the index page, we want to trap those sensibly

    if flash[:notice] == flash_notice
      logger.error "Cowardly aborting rsolr_request_error exception handling, because we redirected to a page that raises another exception"
      raise exception
    end

    logger.error exception

    flash[:notice] = flash_notice
    redirect_to search_action_url
  end
end
