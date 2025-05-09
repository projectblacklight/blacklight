# frozen_string_literal: true

module Blacklight::Catalog
  extend ActiveSupport::Concern

  # MimeResponds is part of ActionController::Base, but not ActionController::API
  include ActionController::MimeResponds

  include Blacklight::Configurable
  include Blacklight::SearchContext
  include Blacklight::Searchable
  include Blacklight::Facetable

  # The following code is executed when someone includes blacklight::catalog in their
  # own controller.
  included do
    if respond_to? :helper_method
      helper_method :sms_mappings, :has_search_parameters?
    end

    record_search_parameters
  end

  # get search results from the solr index
  def index
    @response = search_service.search_results

    respond_to do |format|
      format.html { store_preferred_view }
      format.rss  { render layout: false }
      format.atom { render layout: false }
      format.json do
        @presenter = Blacklight::JsonPresenter.new(@response,
                                                   blacklight_config)
      end
      additional_response_formats(format)
      document_export_formats(format)
    end
  end

  # get a single document from the index
  # to add responses for formats other than html or json see _Blacklight::Document::Export_
  def show
    @document = search_service.fetch(params[:id])

    respond_to do |format|
      format.html { @search_context = setup_next_and_previous_documents }
      format.json
      additional_export_formats(@document, format)
    end
  end

  def advanced_search
    (@response, _deprecated_document_list) = blacklight_advanced_search_form_search_service.search_results
  end

  # get a single document from the index
  def raw
    raise(ActionController::RoutingError, 'Not Found') unless blacklight_config.raw_endpoint.enabled

    @document = search_service.fetch(params[:id])
    render json: @document
  end

  # updates the search counter (allows the show view to paginate)
  def track
    search_session['counter'] = params[:counter]
    search_session['id'] = params[:search_id]
    search_session['per_page'] = params[:per_page]
    search_session['document_id'] = params[:document_id]

    if params[:redirect] && (params[:redirect].starts_with?('/') || params[:redirect] =~ URI::DEFAULT_PARSER.make_regexp)
      uri = URI.parse(params[:redirect])
      path = uri.query ? "#{uri.path}?#{uri.query}" : uri.path
      redirect_to path, status: :see_other
    else
      redirect_to({ action: :show, id: params[:id] }, status: :see_other)
    end
  end

  # displays values and pagination links for a single facet field
  def facet
    # @facet is a Blacklight::Configuration::FacetField
    @facet = blacklight_config.facet_fields[params[:id]]
    raise ActionController::RoutingError, 'Not Found' unless @facet

    @response = if params[:query_fragment].present?
                  facet_search_service.facet_suggest_response(@facet.key, params[:query_fragment])
                else
                  facet_search_service.facet_field_response(@facet.key)
                end

    @display_facet = @response.aggregations[@facet.field]

    # @presenter is a Blacklight::FacetFieldPresenter
    @presenter = @facet.presenter.new(@facet, @display_facet, view_context)
    @pagination = @presenter.paginator
    respond_to do |format|
      format.html do
        # Draw the partial for the "more" facet modal window:
        return render layout: false if request.xhr?
        # Only show the facet names and their values:
        return render 'facet_values', layout: false if params[:only_values]
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

  # Returns the dropdown list for autocomplete
  def suggest
    @suggestions = suggestions_service.suggestions
    render 'suggest', layout: false
  end

  # @return [Array] first value is a Blacklight::Solr::Response and the second
  #                 is a list of documents
  def action_documents
    @documents = search_service.fetch(Array(params[:id]))
    raise Blacklight::Exceptions::RecordNotFound if @documents.blank?

    @documents
  end

  def action_success_redirect_path
    search_state.url_for_document(blacklight_config.document_model.new(id: params[:id]))
  end

  ##
  # Check if any search parameters have been set
  # @return [Boolean]
  def has_search_parameters?
    params[:search_field].present? || search_state.has_constraints?
  end

  private

  #
  # non-routable methods ->
  #

  def render_sms_action?(_config, _options)
    sms_mappings.present?
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
  def additional_response_formats(format)
    blacklight_config.view_config(action_name: :index).respond_to.each do |key, config|
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
  def document_export_formats(format)
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
    options = options.to_h if options.is_a? Blacklight::SearchState
    url_for(options.reverse_merge(action: 'index'))
  end

  # Email Action (this will render the appropriate view on GET requests and process the form and send the email on POST requests)
  def email_action documents
    mail = RecordMailer.email_record(documents, { to: params[:to], message: params[:message], config: blacklight_config }, url_options)
    mail.deliver_now
  end

  # SMS action (this will render the appropriate view on GET requests and process the form and send the email on POST requests)
  def sms_action documents
    to = "#{params[:to].gsub(/[^\d]/, '')}@#{params[:carrier]}"
    mail = RecordMailer.sms_record(documents, { to: to, config: blacklight_config }, url_options)
    mail.deliver_now
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
    Blacklight::Engine.config.blacklight.sms_mappings
  end

  def validate_email_params
    if params[:to].blank?
      flash[:error] = I18n.t('blacklight.email.errors.to.blank')
    elsif !params[:to].match(Blacklight::Engine.config.blacklight.email_regexp)
      flash[:error] = I18n.t('blacklight.email.errors.to.invalid', to: params[:to])
    end

    flash[:error].blank?
  end

  def start_new_search_session?
    action_name == "index"
  end

  def determine_layout
    action_name == 'show' ? 'catalog_result' : super
  end

  def blacklight_advanced_search_form_search_service
    form_search_state = search_state_class.new(blacklight_advanced_search_form_params, blacklight_config, self)

    search_service_class.new(config: blacklight_config, search_state: form_search_state, **search_service_context)
  end

  def blacklight_advanced_search_form_params
    {}
  end
end
