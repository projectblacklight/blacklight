# frozen_string_literal: true
module Blacklight
  class Configuration::FacetField < Blacklight::Configuration::Field
    extend Deprecation

    def normalize! blacklight_config = nil
      query.stringify_keys! if query

      self.collapse = true if collapse.nil?
      self.show = true if show.nil?
      self.if = show if self.if.nil?
      self.index_range = 'A'..'Z' if index_range == true

      if link_to_search
        Deprecation.warn(Blacklight::Configuration::FacetField, '`link_to_search:` is deprecated, use `link_to_facet:` instead')
        self.link_to_facet = link_to_search if link_to_facet.nil?
      end

      super

      if single && tag.blank? && ex.blank?
        self.tag = "#{key}_single"
        self.ex = "#{key}_single"
      end

      self
    end
  end
end
