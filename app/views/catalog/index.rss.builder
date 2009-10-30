xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0") {
        
  xml.channel {
          
    xml.title('Blacklight Catalog Search Results')
    xml.link(formatted_catalog_index_url(:rss, params))
    xml.description('Blacklight Catalog Search Results')
    xml.language('en-us')
    
    @response.docs.each do |doc|
      xml.item do
        xml.title( doc[:title_display])                              
        xml.link(catalog_url(doc[:id]))                                   
        xml.author( doc[:author_display] )                              
      end
    end
          
  }
}
