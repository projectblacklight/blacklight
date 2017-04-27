json.links do
  json.self url_for(search_state.to_h.merge(only_path: false))
  json.prev url_for(search_state.to_h.merge(only_path: false, page: @response.prev_page.to_s)) if @response.prev_page
  json.next url_for(search_state.to_h.merge(only_path: false, page: @response.next_page.to_s)) if @response.next_page
  json.last url_for(search_state.to_h.merge(only_path: false, page: @response.total_pages.to_s))
end

json.meta do
  json.pages @presenter.pagination_info
end

json.data do
  json.array! @presenter.documents do |document|
    json.id document.id
    json.attributes document
    json.links do
      json.self polymorphic_url(url_for_document(document))
    end
  end
end

json.included do
  json.array! @presenter.search_facets_as_json do |facet|
    json.type 'facet'
    json.id facet['name']
    json.attributes do
      json.items do
        json.array! facet['items'] do |item|
          json.id
          json.attributes do
            json.label item['label']
            json.value item['value']
            json.hits item['hits']
          end
          json.links do
            json.self path_for_facet(facet['name'], item['value'])
          end
        end
      end
    end
    json.links do
      json.self search_facet_url(id: facet['name'])
    end
  end
end
