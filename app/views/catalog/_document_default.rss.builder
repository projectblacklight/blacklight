xml.item do  
  xml.title(presenter(document).render_document_index_label(document_show_link_field(document)) || (document.to_semantic_values[:title].first if document.to_semantic_values.key?(:title)))
  xml.link(polymorphic_url(url_for_document(document)))
  xml.author( document.to_semantic_values[:author].first ) if document.to_semantic_values.key? :author
end