# frozen_string_literal: true
module Blacklight
  class Configuration::SortField < Blacklight::Configuration::Field
    def normalize! blacklight_config = nil
      super
      self.field ||= label.try(:parameterize)
      self.field ||= sort

      self.sort ||= self.field

      self
    end

    def validate!
      raise ArgumentError.new, "Must supply a sort string" if self.sort.nil?
    end
  end
end
