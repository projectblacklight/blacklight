xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0") {
        
  xml.channel {
          
    xml.title(t('catalog.title', :application_name => application_name))
    xml.link(catalog_index_url(params))
    xml.description(t('catalog.title', :application_name => application_name))
    xml.language('en-us')
    @document_list.each do |doc|
      xml.item do  
        xml.title( doc.to_semantic_values[:title][0] || doc.id )                              
        xml.link(catalog_url(doc[:id]))                                   
        xml.author( doc.to_semantic_values[:author][0] ) if doc.to_semantic_values[:author][0]       
      end
    end
          
  }
}
