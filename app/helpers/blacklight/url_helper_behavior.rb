# frozen_string_literal: true

##
# URL helper methods
module Blacklight::UrlHelperBehavior
  # Uses the catalog_path route to create a link to the show page for an item.
  # catalog_path accepts a hash. The solr query params are stored in the session,
  # so we only need the +counter+ param here. We also need to know if we are viewing to document as part of search results.
  # TODO: move this to the IndexPresenter
  # @param doc [SolrDocument] the document
  # @param field_or_opts [Hash, String] either a string to render as the link text or options
  # @param opts [Hash] the options to create the link with
  # @option opts [Number] :counter (nil) the count to set in the session (for paging through a query result)
  # @example Passing in an image
  #   link_to_document(doc, '<img src="thumbnail.png">', counter: 3) #=> "<a href=\"catalog/123\" data-context-href=\"/catalog/123/track?counter=3&search_id=999\"><img src="thumbnail.png"></a>
  # @example With the default document link field
  #   link_to_document(doc, counter: 3) #=> "<a href=\"catalog/123\" data-context-href=\"/catalog/123/track?counter=3&search_id=999\">My Title</a>
  def link_to_document(doc, field_or_opts = nil, opts = { counter: nil })
    label = case field_or_opts
            when NilClass
              document_presenter(doc).heading
            when Hash
              opts = field_or_opts
              document_presenter(doc).heading
            else # String
              field_or_opts
            end

    link_to label, search_state.url_for_document(doc), document_link_params(doc, opts)
  end

  # @private
  def document_link_params(doc, opts)
    session_tracking_params(doc, opts[:counter]).deep_merge(opts.except(:label, :counter))
  end
  private :document_link_params

  ##
  # Attributes for a link that gives a URL we can use to track clicks for the current search session
  # @param [SolrDocument] document
  # @param [Integer] counter
  # @example
  #   session_tracking_params(SolrDocument.new(id: 123), 7)
  #   => { data: { context_href: '/catalog/123/track?counter=7&search_id=999' } }
  def session_tracking_params document, counter, per_page: search_session['per_page'], search_id: current_search_session&.id
    path_params = { per_page: params.fetch(:per_page, per_page), counter: counter, search_id: search_id }
    if blacklight_config.track_search_session.storage == 'server'
      path_params[:document_id] = document&.id
      path_params[:search_id] = search_id
    end
    path = session_tracking_path(document, path_params)
    return {} if path.nil?

    context_method = blacklight_config.track_search_session.storage == 'client' ? 'get' : 'post'
    { data: { context_href: path, context_method: context_method } }
  end

  ##
  # Get the URL for tracking search sessions across pages using polymorphic routing
  def session_tracking_path document, params = {}
    return if document.nil? || !blacklight_config.track_search_session.storage

    if main_app.respond_to?(controller_tracking_method)
      return main_app.public_send(controller_tracking_method, params.merge(id: document))
    end

    raise "Unable to find #{controller_tracking_method} route helper. " \
          "Did you add `concerns :searchable` routing mixin to your `config/routes.rb`?"
  end

  def controller_tracking_method
    return "solr_document_path" if blacklight_config.track_search_session.storage == 'client'

    "track_#{controller_name}_path"
  end

  #
  # link based helpers ->
  #

  # Create a link back to the index screen, keeping the user's facet, query and paging choices intact by using session.
  # @example
  #   link_back_to_catalog(label: 'Back to Search')
  #   link_back_to_catalog(label: 'Back to Search', route_set: my_engine)
  def link_back_to_catalog(opts = { label: nil })
    scope = opts.delete(:route_set) || self
    query_params = search_state.reset(current_search_session.try(:query_params)).to_hash

    if search_session['counter']
      per_page = (search_session['per_page'] || blacklight_config.default_per_page).to_i
      counter = search_session['counter'].to_i

      query_params[:per_page] = per_page unless search_session['per_page'].to_i == blacklight_config.default_per_page
      query_params[:page] = ((counter - 1) / per_page) + 1
    end

    link_url = if query_params.empty?
                 search_action_path(only_path: true)
               else
                 scope.url_for(query_params)
               end
    label = opts.delete(:label)

    if link_url =~ /bookmarks/
      label ||= t('blacklight.back_to_bookmarks')
    end

    label ||= t('blacklight.back_to_search')

    link_to label, link_url, opts
  end

  # Use in e.g. the search history display, where we want something more like text instead of the normal constraints
  def link_to_previous_search(params)
    search_state = controller.search_state_class.new(params, blacklight_config, self)
    link_to(render(Blacklight::ConstraintsComponent.for_search_history(search_state: search_state)), search_action_path(params))
  end
end
