# frozen_string_literal: true

module Blacklight
  class SearchHeaderComponent < Blacklight::Component
    # Should we draw the did_you_mean component?
    # Currently not supported with elasticsearch
    def did_you_mean?
      Blacklight.solr?
    end
  end
end
