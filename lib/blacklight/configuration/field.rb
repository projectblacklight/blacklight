# frozen_string_literal: true
module Blacklight
  class Configuration::Field < OpenStructWithHashAccess
    def normalize! blacklight_config = nil
      self.field ||= self.key
      self.key ||= self.field

      self.label ||= default_label

      self.if = true if self.if.nil?
      self.unless = false if self.unless.nil?

      self
    end
  
    def validate!
      raise ArgumentError, "Must supply a field name" if self.field.nil?
    end

    def default_label
      if self.key.respond_to?(:titleize)
        self.key.try(:titleize)
      else
        self.key.to_s.titleize
      end
    end
  end
end
