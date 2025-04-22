# frozen_string_literal: true

module Blacklight::SearchContext
  extend ActiveSupport::Concern

  # The following code is executed when someone includes Blacklight::Catalog::SearchSession in their
  # own controller.
  included do
    if respond_to? :helper_method
      helper_method :current_search_session, :search_session
    end
  end

  class_methods do
    # Save the submitted search parameters in the search session
    def record_search_parameters opts = { only: :index }
      before_action :set_current_search_session, opts
    end
  end

  # The current search session
  def current_search_session
    @current_search_session ||= find_search_session
  end

  # Returns a list of Searches from the ids in the user's history.
  def searches_from_history
    session[:history].blank? ? ::Search.none : ::Search.where(id: session[:history]).order("updated_at desc")
  end

  # GET previous and next document json for the document specified by
  # the counter param in current search
  def page_links
    counter_param = params.delete(:counter)
    @page_link_data = {}
    if counter_param
      index = counter_param.to_i - 1
      response, documents = search_service.previous_and_next_documents_for_search index, search_state.reset_search
      if documents.detect(&:present?)
        @page_link_data[:prev] = page_links_document_path(documents.first, index)
        @page_link_data[:next] = page_links_document_path(documents.last, index + 2)
      end
      if response&.total&.positive?
        @page_link_data[:counterRaw] = counter_param
        @page_link_data[:counterDelimited] = helpers.number_with_delimiter(counter_param.to_i)
        @page_link_data[:totalRaw] = response.total
        @page_link_data[:totalDelimited] = helpers.number_with_delimiter(response.total)
      end
    end
    render json: @page_link_data
  end

  private

  # sets up the session[:search] hash if it doesn't already exist
  def search_session
    session[:search] ||= {}
    # Need to call the getter again. The value is mutated
    # https://github.com/rails/rails/issues/23884
    session[:search]
  end

  # Persist the current search session id to the user's session
  def set_current_search_session
    search_session['id'] = current_search_session.id if current_search_session
  end

  def find_search_session
    if agent_is_crawler?
      nil
    elsif params[:search_context].present?
      find_or_initialize_search_session_from_params JSON.parse(params[:search_context])
    elsif params[:search_id].present?
      begin
        # TODO: check the search id signature.
        searches_from_history.find(params[:search_id])
      rescue ActiveRecord::RecordNotFound
        nil
      end
    elsif start_new_search_session?
      find_or_initialize_search_session_from_params search_state.to_h
    elsif search_session['id']
      begin
        searches_from_history.find(search_session['id'])
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end
  end

  ##
  # If the current action should start a new search session, this should be
  # set to true
  def start_new_search_session?
    false
  end

  ##
  # Determine if the current request is coming from an anonymous bot
  # or search crawler
  #
  def agent_is_crawler?
    crawler_proc = blacklight_config.crawler_detector
    return false if crawler_proc.nil? || (defined?(current_user) && current_user.present?)

    crawler_proc.call(request)
  end

  def find_or_initialize_search_session_from_params params
    return unless blacklight_config.track_search_session.storage == 'server'

    params_copy = params.reject { |k, v| nonpersisted_search_session_params.include?(k.to_sym) || v.blank? }

    return if params_copy.reject { |k, _v| [:action, :controller].include? k.to_sym }.blank?

    saved_search = searches_from_history.find { |x| x.query_params == params_copy }

    saved_search || Search.create(query_params: params_copy).tap do |s|
      add_to_search_history(s)
    end
  end

  # Add a search to the in-session search history list
  def add_to_search_history search
    session[:history] ||= []

    session[:history].unshift(search.id)

    if session[:history].length > blacklight_config.search_history_window
      session[:history] = session[:history].slice(0, blacklight_config.search_history_window)
    end
  end

  # A list of query parameters that should not be persisted for a search
  def nonpersisted_search_session_params
    unless method(:blacklisted_search_session_params).source_location.first.end_with?('deprecation/method_wrappers.rb')
      # The blacklisted_search_session_params was overridden, so call it.
      Blacklight.deprecation.warn(self, "blacklisted_search_session_params was overriden in your app, " \
                                        "but that method should be renamed to `nonpersisted_search_session_params'. " \
                                        "The original behavior will be removed in the next major release.")
      return blacklisted_search_session_params
    end
    [:commit, :counter, :total, :search_id, :page, :per_page]
  end

  def blacklisted_search_session_params
    nonpersisted_search_session_params
  end
  Blacklight.deprecation.deprecate_methods(self, blacklisted_search_session_params: 'use nonpersisted_search_session_params instead')

  # calls setup_previous_document then setup_next_document.
  # used in the show action for single view pagination.
  def setup_next_and_previous_documents
    return { counter: params[:counter] } if setup_next_and_previous_on_client?
    return nil unless setup_next_and_previous_on_server?

    index = search_session['counter'].to_i - 1
    response, documents = search_service.previous_and_next_documents_for_search index, search_state.reset(current_search_session.query_params)

    search_session['total'] = response.total
    { prev: documents.first, next: documents.last }
  rescue Blacklight::Exceptions::InvalidRequest => e
    logger&.warn "Unable to setup next and previous documents: #{e}"
    nil
  end

  def setup_next_and_previous_on_server?
    search_session['counter'] && current_search_session && blacklight_config.track_search_session.storage == 'server'
  end

  def setup_next_and_previous_on_client?
    params[:counter] && blacklight_config.track_search_session.storage == 'client'
  end

  def page_links_document_path(document, counter)
    return nil unless document
    return search_state.url_for_document(document, counter: counter) if blacklight_config.view_config(:show).route

    solr_document_path(document, counter: counter)
  end
end
