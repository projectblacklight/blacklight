require 'base64'

xml.instruct!(:xml, :encoding => "UTF-8")

xml.feed("xmlns" => "http://www.w3.org/2005/Atom",
         "xmlns:opensearch"=>"http://a9.com/-/spec/opensearch/1.1/") do

  xml.title   t('blacklight.search.title', :application_name => application_name)
  # an author is required, so we'll just use the app name
  xml.author { xml.name application_name }
  
  xml.link    "rel" => "self", "href" => url_for(search_state.to_h.merge(only_path: false))
  xml.link    "rel" => "alternate", "href" => url_for(search_state.to_h.merge(:only_path => false, :format => "html")), "type" => "text/html"
  xml.id      url_for(search_state.to_h.merge(:only_path => false, :format => "html", :content_format => nil, "type" => "text/html"))

  # Navigational and context links
  
  xml.link( "rel" => "next", 
            "href" => url_for(search_state.to_h.merge(:only_path => false, :page => @response.next_page.to_s))
           ) if @response.next_page
  
  xml.link( "rel" => "previous", 
            "href" => url_for(search_state.to_h.merge(:only_path => false, :page => @response.prev_page.to_s))
           ) if @response.prev_page
           
  xml.link( "rel" => "first", 
            "href" => url_for(search_state.to_h.merge(:only_path => false, :page => "1")))
  
  xml.link( "rel" => "last",
            "href" => url_for(search_state.to_h.merge(:only_path => false, :page => @response.total_pages.to_s)))
  
  # "search" doesn't seem to actually be legal, but is very common, and
  # used as an example in opensearch docs
  xml.link( "rel" => "search",
            "type" => "application/opensearchdescription+xml",
            "href" =>  url_for(:controller=>'catalog',:action => 'opensearch', :format => 'xml', :only_path => false))

  # opensearch response elements
  xml.opensearch :totalResults, @response.total.to_s
  xml.opensearch :startIndex, @response.start.to_s
  xml.opensearch :itemsPerPage, @response.limit_value
  xml.opensearch :Query, :role => "request", :searchTerms => params[:q], :startPage => @response.current_page
  
  
  # updated is required, for now we'll just set it to now, sorry
  xml.updated Time.current.iso8601
  
  @document_list.each_with_index do |document, document_counter|
    xml << Nokogiri::XML.fragment(render_document_partials(document, blacklight_config.view_config(:atom).partials, document_counter: document_counter))
  end
end





