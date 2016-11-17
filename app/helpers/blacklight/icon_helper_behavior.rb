##
# Module to help generate icon helpers for SVG images
module Blacklight::IconHelperBehavior
  ##
  # Returns the raw SVG (String) for a Blacklight Icon located in 
  # app/assets/images/blacklight/*.svg. Caches them so we don't have to look up
  # the svg everytime.
  # @param [String, Symbol] icon_name
  # @return [String]
  def blacklight_icon(icon_name, options = {})
    Rails.cache.fetch([:blacklight_icons, icon_name, options]) do
      icon = Blacklight::Icon.new(icon_name, options)
      content_tag(:span, icon.svg.html_safe, icon.options)
    end    
  end
end
