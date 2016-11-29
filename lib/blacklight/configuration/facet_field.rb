# frozen_string_literal: true
module Blacklight
  class Configuration::FacetField < Blacklight::Configuration::Field
    extend Deprecation

    def normalize! blacklight_config = nil
      self.query.stringify_keys! if self.query

      self.collapse = true if self.collapse.nil?
      self.show = true if self.show.nil?
      self.if = self.show if self.if.nil?
      self.index_range = 'A'..'Z' if self.index_range == true

      if self.link_to_search
        Deprecation.warn(Blacklight::Configuration::FacetField, '`link_to_search:` is deprecated, use `link_to_facet:` instead')
        self.link_to_facet = self.link_to_search if self.link_to_facet.nil?
      end

      super

      if self.single && self.tag.blank? && self.ex.blank?
        self.tag = "#{self.key}_single"
        self.ex = "#{self.key}_single"
      end

      self
    end
  end
end
