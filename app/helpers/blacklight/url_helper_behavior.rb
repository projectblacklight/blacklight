# frozen_string_literal: true
##
# URL helper methods
module Blacklight::UrlHelperBehavior
  def url_for_document(doc, options = {})
    search_state.url_for_document(doc, options)
  end

  # link_to_document(doc, 'VIEW', :counter => 3)
  # Use the catalog_path RESTful route to create a link to the show page for a specific item.
  # catalog_path accepts a hash. The solr query params are stored in the session,
  # so we only need the +counter+ param here. We also need to know if we are viewing to document as part of search results.
  # TODO: move this to the IndexPresenter
  def link_to_document(doc, field_or_opts = nil, opts = { :counter => nil })
    if field_or_opts.is_a? Hash
      opts = field_or_opts
    else
      field = field_or_opts
    end

    field ||= document_show_link_field(doc)
    label = index_presenter(doc).label field, opts
    link_to label, url_for_document(doc), document_link_params(doc, opts)
  end

  def document_link_params(doc, opts)
    session_tracking_params(doc, opts[:counter]).deep_merge(opts.except(:label, :counter))
  end
  private :document_link_params

  ##
  # Link to the previous document in the current search context
  def link_to_previous_document(previous_document)
    link_opts = session_tracking_params(previous_document, search_session['counter'].to_i - 1).merge(:class => "previous", :rel => 'prev')
    link_to_unless previous_document.nil?, raw(t('views.pagination.previous')), url_for_document(previous_document), link_opts do
      content_tag :span, raw(t('views.pagination.previous')), :class => 'previous'
    end
  end

  ##
  # Link to the next document in the current search context
  def link_to_next_document(next_document)
    link_opts = session_tracking_params(next_document, search_session['counter'].to_i + 1).merge(:class => "next", :rel => 'next')
    link_to_unless next_document.nil?, raw(t('views.pagination.next')), url_for_document(next_document), link_opts do
      content_tag :span, raw(t('views.pagination.next')), :class => 'next'
    end
  end

  ##
  # Attributes for a link that gives a URL we can use to track clicks for the current search session
  # @param [SolrDocument] document
  # @param [Integer] counter
  # @example
  #   session_tracking_params(SolrDocument.new(id: 123), 7)
  #   => { data: { :'tracker-href' => '/catalog/123/track?counter=7&search_id=999' } }
  def session_tracking_params document, counter
    path = session_tracking_path(document, per_page: params.fetch(:per_page, search_session['per_page']), counter: counter, search_id: current_search_session.try(:id))

    if path.nil?
      return {}
    end

    { data: { :'context-href' => path } }
  end
  private :session_tracking_params

  ##
  # Get the URL for tracking search sessions across pages using polymorphic routing
  def session_tracking_path document, params = {}
    return if document.nil?

    if respond_to?(controller_tracking_method)
      send(controller_tracking_method, params.merge(id: document))
    else
      blacklight.track_search_context_path(params.merge(id: document))
    end
  end

  def controller_tracking_method
    "track_#{controller_name}_path"
  end

  #
  # link based helpers ->
  #

  # create link to query (e.g. spelling suggestion)
  def link_to_query(query)
    p = search_state.to_h.except(:page, :action)
    p[:q] = query
    link_to(query, search_action_path(p))
  end

  ##
  # Get the path to the search action with any parameters (e.g. view type)
  # that should be persisted across search sessions.
  def start_over_path query_params = params
    h = {}
    current_index_view_type = document_index_view_type(query_params)
    h[:view] = current_index_view_type unless current_index_view_type == default_document_index_view_type

    search_action_path(h)
  end

  # Create a link back to the index screen, keeping the user's facet, query and paging choices intact by using session.
  # @example
  #   link_back_to_catalog(label: 'Back to Search')
  #   link_back_to_catalog(label: 'Back to Search', route_set: my_engine)
  def link_back_to_catalog(opts = { :label => nil })
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

  # Search History and Saved Searches display
  def link_to_previous_search(params)
    link_to(render_search_to_s(params), search_action_path(params))
  end

  # Get url parameters to a search within a grouped result set
  #
  # @param [Blacklight::Solr::Response::Group] group
  # @return [Hash]
  def add_group_facet_params_and_redirect group
    search_state.add_facet_params_and_redirect(group.field, group.key)
  end

  # A URL to refworks export, with an embedded callback URL to this app.
  # the callback URL is to bookmarks#export, which delivers a list of
  # user's bookmarks in 'refworks marc txt' format -- we tell refworks
  # to expect that format.
  def bookmarks_export_url(format, params = {})
    bookmarks_url(params.merge(format: format, encrypted_user_id: encrypt_user_id(current_or_guest_user.id)))
  end
end
