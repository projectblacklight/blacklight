xml.item do  
  xml.title( document.to_semantic_values[:title][0] || presenter(document).render_document_index_label(document_show_link_field(document)) )                              
  xml.link(polymorphic_url(url_for_document(document)))                                   
  xml.author( document.to_semantic_values[:author][0] ) if document.to_semantic_values[:author][0]       
end