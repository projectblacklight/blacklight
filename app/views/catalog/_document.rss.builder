# frozen_string_literal: true

xml.item do
  xml.title(document_presenter(document).heading || (document.to_semantic_values[:title].first if document.to_semantic_values.key?(:title)))
  Deprecation.silence(Blacklight::UrlHelperBehavior) do
    xml.link(polymorphic_url(url_for_document(document)))
  end
  xml.author( document.to_semantic_values[:author].first ) if document.to_semantic_values.key? :author
end
