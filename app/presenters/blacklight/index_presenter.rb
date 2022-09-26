# frozen_string_literal: true

module Blacklight
  class IndexPresenter < DocumentPresenter
    def view_config
      configuration.view_config(view_context.document_index_view_type)
    end
  end
end
