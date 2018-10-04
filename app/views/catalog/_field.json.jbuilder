# frozen_string_literal: true

json.set!(field_name) do
  json.id "#{document_url}##{field_name}"
  json.type 'document_value'
  json.attributes do
    json.value doc_presenter.field_value(field_name)
    json.label field.label
  end
end
