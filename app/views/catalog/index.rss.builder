xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0") {
  xml.channel {
    xml.title(t('blacklight.search.title', :application_name => application_name))
    xml.link(search_action_url(params.to_unsafe_h))
    xml.description(t('blacklight.search.title', :application_name => application_name))
    xml.language('en-us')
    @document_list.each_with_index do |document, document_counter|
      xml << Nokogiri::XML.fragment(render_document_partials(document, blacklight_config.view_config(:rss).partials, document_counter: document_counter))
    end
  }
}
