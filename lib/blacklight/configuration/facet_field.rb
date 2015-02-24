module Blacklight
  class Configuration::FacetField < Blacklight::Configuration::Field
    def normalize! blacklight_config = nil
      self.query.stringify_keys! if self.query

      self.collapse = true if self.collapse.nil?
      self.show = true if self.show.nil?
      self.if ||= self.show

      super
      
      if self.single and self.tag.blank? and self.ex.blank?
        self.tag = "#{self.key}_single"
        self.ex = "#{self.key}_single"
      end

      self
    end
  end
end
