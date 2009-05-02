#
# Methods added to this helper will be available to all templates in the application.
#
module ApplicationHelper
  
  def application_name
    'Blacklight'
  end
  
  # Search History display
  def link_to_previous_search(params)
    query_part = params[:qt] == Blacklight.config[:default_qt] ? params[:q] : "#{params[:qt]}:(#{params[:q]})"
    facet_part = 
    if params[:f]
      tmp = 
      params[:f].collect do |pair|
        "#{Blacklight.config[:facet][:labels][pair.first]}:#{pair.last}"
      end.join(" AND ")
      "{#{tmp}}"
    else
      ""
    end
    link_to("#{query_part} #{facet_part}", catalog_index_path(params))
  end
  
end