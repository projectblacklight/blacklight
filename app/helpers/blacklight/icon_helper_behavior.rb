# frozen_string_literal: true

##
# Module to help generate icon helpers for SVG images
module Blacklight::IconHelperBehavior
  ##
  # Returns the raw SVG (String) for a Blacklight Icon
  # @param [String, Symbol] icon_name
  # @return [String]
  def blacklight_icon(icon_name, **)
    render "Blacklight::Icons::#{icon_name.to_s.camelize}Component".constantize.new(**)
  end
end
