# frozen_string_literal: true

# The Searchable module can be included onto classes that need to initialize a SearchService.
# There are three dependencies you must provide on the including class. Typically these
# would be provided by Blacklight::Controller
#  1. search_state
#  2. blacklight_config
#
# Additionally, the including class may override the search_service_context method to provide
# further context to the SearchService. For example you could override this to provide the
# currently signed in user.
module Blacklight::Searchable
  extend ActiveSupport::Concern

  included do
    # Which class to use for the search service. You can subclass SearchService if you
    # want to override any of the methods (e.g. SearchService#fetch)
    class_attribute :search_service_class
    self.search_service_class = Blacklight::SearchService

    # Which class to use for the search state. You can subclass SearchState if you
    # want to override any of the methods (e.g. SearchState#url_for_document)
    class_attribute :search_state_class
    self.search_state_class = Blacklight::SearchState

    helper_method :search_state if respond_to? :helper_method
  end

  # @return [Blacklight::SearchService]
  def search_service
    search_service_class.new(config: blacklight_config, search_state: search_state, **search_service_context)
  end

  # Override this method on the class that includes Blacklight::Searchable to provide more context to the search service if necessary.
  # For example, if your search builder needs to be aware of the current user, override this method to return a hash including the current user.
  # Then the search builder could use some property about the current user to construct a constraint on the search.
  # @return [Hash] a hash of context information to pass through to the search service
  def search_service_context
    {}
  end

  # @return [Blacklight::SuggestSearch]
  def suggestions_service
    Blacklight::SuggestSearch.new(params, search_service.repository).suggestions
  end

  # This must be on every controller that uses the layout, because it is used in
  # the header to draw Blacklight::SearchNavbarComponent
  # @return [Blacklight::SearchState] a memoized instance of the parameter state.
  def search_state
    @search_state ||= search_state_class.new(params, blacklight_config, self)
  end
end
