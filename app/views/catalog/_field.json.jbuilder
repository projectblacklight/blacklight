# frozen_string_literal: true

json.set!(field_name) do
  json.id "#{document_url}##{field_name}"
  json.type 'document_value'
  json.attributes do
    json.value field_presenter.render
    json.label field_presenter.label(view_type)
  end
end
