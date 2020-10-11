# frozen_string_literal: true
##
# URL helper methods
module Blacklight::UrlHelperBehavior
  extend Deprecation

  # @deprecated
  def url_for_document(doc, options = {})
    search_state.url_for_document(doc, options)
  end
  deprecation_deprecate url_for_document: 'Use SearchState#url_for_document directly'

  # Uses the catalog_path route to create a link to the show page for an item.
  # catalog_path accepts a hash. The solr query params are stored in the session,
  # so we only need the +counter+ param here. We also need to know if we are viewing to document as part of search results.
  # TODO: move this to the IndexPresenter
  # @param doc [SolrDocument] the document
  # @param field_or_opts [Hash, String] either a string to render as the link text or options
  # @param opts [Hash] the options to create the link with
  # @option opts [Number] :counter (nil) the count to set in the session (for paging through a query result)
  # @example Passing in an image
  #   link_to_document(doc, '<img src="thumbnail.png">', counter: 3) #=> "<a href=\"catalog/123\" data-tracker-href=\"/catalog/123/track?counter=3&search_id=999\"><img src="thumbnail.png"></a>
  # @example With the default document link field
  #   link_to_document(doc, counter: 3) #=> "<a href=\"catalog/123\" data-tracker-href=\"/catalog/123/track?counter=3&search_id=999\">My Title</a>
  def link_to_document(doc, field_or_opts = nil, opts = { counter: nil })
    label = case field_or_opts
            when NilClass
              document_presenter(doc).heading
            when Hash
              opts = field_or_opts
              document_presenter(doc).heading
            when Proc, Symbol
              Deprecation.warn(self, "passing a #{field_or_opts.class} to link_to_document is deprecated and will be removed in Blacklight 8")
              Deprecation.silence(Blacklight::IndexPresenter) do
                index_presenter(doc).label field_or_opts, opts
              end
            else # String
              field_or_opts
            end

    Deprecation.silence(Blacklight::UrlHelperBehavior) do
      link_to label, url_for_document(doc), document_link_params(doc, opts)
    end
  end

  # @private
  def document_link_params(doc, opts)
    session_tracking_params(doc, opts[:counter]).deep_merge(opts.except(:label, :counter))
  end
  private :document_link_params

  ##
  # Link to the previous document in the current search context
  # @deprecated
  def link_to_previous_document(previous_document)
    link_opts = session_tracking_params(previous_document, search_session['counter'].to_i - 1).merge(class: "previous", rel: 'prev')
    link_to_unless previous_document.nil?, raw(t('views.pagination.previous')), url_for_document(previous_document), link_opts do
      tag.span raw(t('views.pagination.previous')), class: 'previous'
    end
  end
  deprecation_deprecate link_to_previous_document: 'Moving to Blacklight::SearchContextComponent'

  ##
  # Link to the next document in the current search context
  # @deprecated
  def link_to_next_document(next_document)
    link_opts = session_tracking_params(next_document, search_session['counter'].to_i + 1).merge(class: "next", rel: 'next')
    link_to_unless next_document.nil?, raw(t('views.pagination.next')), url_for_document(next_document), link_opts do
      tag.span raw(t('views.pagination.next')), class: 'next'
    end
  end
  deprecation_deprecate link_to_previous_document: 'Moving to Blacklight::SearchContextComponent'

  ##
  # Attributes for a link that gives a URL we can use to track clicks for the current search session
  # @private
  # @param [SolrDocument] document
  # @param [Integer] counter
  # @example
  #   session_tracking_params(SolrDocument.new(id: 123), 7)
  #   => { data: { :'context-href' => '/catalog/123/track?counter=7&search_id=999' } }
  def session_tracking_params document, counter
    path = session_tracking_path(document, per_page: params.fetch(:per_page, search_session['per_page']), counter: counter, search_id: current_search_session.try(:id), document_id: document&.id)

    if path.nil?
      return {}
    end

    { data: { 'context-href': path } }
  end
  private :session_tracking_params

  ##
  # Get the URL for tracking search sessions across pages using polymorphic routing
  def session_tracking_path document, params = {}
    return if document.nil? || !blacklight_config&.track_search_session

    if main_app.respond_to?(controller_tracking_method)
      return main_app.public_send(controller_tracking_method, params.merge(id: document))
    end

    raise "Unable to find #{controller_tracking_method} route helper. " \
    "Did you add `concerns :searchable` routing mixin to your `config/routes.rb`?"
  end

  def controller_tracking_method
    "track_#{controller_name}_path"
  end

  #
  # link based helpers ->
  #

  # create link to query (e.g. spelling suggestion)
  # @deprecated
  def link_to_query(query)
    p = search_state.to_h.except(:page, :action)
    p[:q] = query
    link_to(query, search_action_path(p))
  end
  deprecation_deprecate link_to_query: 'Removed without replacement'

  ##
  # Get the path to the search action with any parameters (e.g. view type)
  # that should be persisted across search sessions.
  # @deprecated
  def start_over_path query_params = params
    h = {}
    current_index_view_type = document_index_view_type(query_params)
    h[:view] = current_index_view_type unless current_index_view_type == default_document_index_view_type

    search_action_path(h)
  end
  deprecation_deprecate start_over_path: 'Removed without replacement'

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

  # Search History and Saved Searches display
  def link_to_previous_search(params)
    link_to(render_search_to_s(params), search_action_path(params))
  end

  # Get url parameters to a search within a grouped result set
  #
  # @deprecated
  # @param [Blacklight::Solr::Response::Group] group
  # @return [Hash]
  def add_group_facet_params_and_redirect group
    search_state.add_facet_params_and_redirect(group.field, group.key)
  end
  deprecation_deprecate add_group_facet_params_and_redirect: 'Removed without replacement'

  # A URL to refworks export, with an embedded callback URL to this app.
  # the callback URL is to bookmarks#export, which delivers a list of
  # user's bookmarks in 'refworks marc txt' format -- we tell refworks
  # to expect that format.
  # @deprecated
  def bookmarks_export_url(format, params = {})
    bookmarks_url(params.merge(format: format, encrypted_user_id: encrypt_user_id(current_or_guest_user.id)))
  end
  deprecation_deprecate bookmarks_export_url: 'Removed without replacement'
end
