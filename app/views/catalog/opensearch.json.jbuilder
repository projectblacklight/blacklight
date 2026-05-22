# frozen_string_literal: true

json.array! [search_state.query_param] + @presenter.documents.map { |document| document_presenter(document).heading }.uniq
