# frozen_string_literal: true
module Blacklight
  class Configuration::FacetField < Blacklight::Configuration::Field
    def normalize! blacklight_config = nil
      self.query.stringify_keys! if self.query

      self.collapse = true if self.collapse.nil?
      self.show = true if self.show.nil?
      self.if = self.show if self.if.nil?
      self.index_range = 'A'..'Z' if self.index_range == true

      super
      
      if self.single and self.tag.blank? and self.ex.blank?
        self.tag = "#{self.key}_single"
        self.ex = "#{self.key}_single"
      end

      self
    end
  end
end
