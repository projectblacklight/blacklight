module Blacklight::Catalog::SearchContext
  extend ActiveSupport::Concern


  # The following code is executed when someone includes blacklight::catalog::search_session in their
  # own controller.
  included do  
    helper_method :current_search_session, :search_session
    before_filter :search_session, :history_session, :current_search_session
  end
  
  protected

  # sets up the session[:history] hash if it doesn't already exist.
  # assigns all Search objects (that match the searches in session[:history]) to a variable @searches.
  def history_session
    session[:history] ||= []
    @searches = searches_from_history # <- in BlacklightController
  end

  # sets up the session[:search] hash if it doesn't already exist
  def search_session
    session[:search] ||= {}
  end
  
  # The current search session 
  def current_search_session

    @current_search_session ||= if action_name == "index"
      find_or_initialize_search_session_from_params params
    elsif params[:search_context] and !params[:search_context].blank?
      find_or_initialize_search_session_from_params JSON.load(params[:search_context])
    elsif params[:search_id] and !params[:search_id].blank?
      # TODO : check the search id signature.
      searches_from_history.find(params[:search_id]) rescue nil
    elsif search_session[:id]
      searches_from_history.find(search_session[:id]) rescue nil
    end

    if @current_search_session
      search_session[:id] = @current_search_session.id
    end

    @current_search_session
  end

  def find_or_initialize_search_session_from_params params
    params_copy = params.reject { |k,v| blacklisted_search_session_params.include?(k.to_sym) or v.blank? }

    return if params_copy.reject { |k,v| [:action, :controller].include? k.to_sym }.blank?

    saved_search = searches_from_history.select { |x| x.query_params == params_copy }.first

    saved_search ||= begin
      s = Search.create(:query_params => params_copy)
      add_to_search_history(s)
      s
    end
  end

  # Add a search to the in-session search history list
  def add_to_search_history search
    session[:history] ||= []

    session[:history].unshift(search.id)

    if session[:history].length > blacklight_config.search_history_window

      session[:history] = session[:history].slice(0, blacklight_config.search_history_window )
      
    end
  end

  # A list of query parameters that should not be persisted for a search      
  def blacklisted_search_session_params
    [:commit, :counter, :total, :search_id, :page, :per_page]
  end

  # calls setup_previous_document then setup_next_document.
  # used in the show action for single view pagination.
  def setup_next_and_previous_documents
    if search_session[:counter] and current_search_session
      index = search_session[:counter].to_i - 1
      response, documents = get_previous_and_next_documents_for_search index, current_search_session.query_params

      search_session[:total] = response.total
      @search_context_response = response
      @previous_document = documents.first
      @next_document = documents.last
    end
  end

end