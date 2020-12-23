# frozen_string_literal: true
##
# URL helper methods
module Blacklight::UrlHelperBehavior
  extend Deprecation

  # # @private
  # def document_link_params(doc, opts)
  #   session_tracking_params(doc, opts[:counter]).deep_merge(opts.except(:label, :counter))
  # end
  # private :document_link_params

  ##
  # Attributes for a link that gives a URL we can use to track clicks for the current search session
  # @param [SolrDocument] document
  # @param [Integer] counter
  # @example
  #   session_tracking_params(SolrDocument.new(id: 123), 7)
  #   => { data: { :'context-href' => '/catalog/123/track?counter=7&search_id=999' } }
  def session_tracking_params document, counter, per_page: search_session['per_page'], search_id: current_search_session&.id
    path = session_tracking_path(document, per_page: params.fetch(:per_page, per_page), counter: counter, search_id: search_id, document_id: document&.id)

    if path.nil?
      return {}
    end

    { data: { 'context-href': path } }
  end

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
end
