# frozen_string_literal: true

document_url = polymorphic_url(@document)
json.links do
  json.self document_url
end

json.data do
  json.id @document.id
  json.type @document[blacklight_config.view_config(:show).display_type_field]
  json.attributes do
    doc_presenter = show_presenter(@document)

    doc_presenter.fields.each do |field_name, field|
      next unless should_render_show_field? @document, field
      json.partial! 'field', field: field,
                             field_name: field_name,
                             document_url: document_url,
                             doc_presenter: doc_presenter
    end
  end
end
