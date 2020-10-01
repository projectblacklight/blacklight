# frozen_string_literal: true
module Blacklight
  class Configuration::Field < OpenStructWithHashAccess
    # @!attribute field
    #   @return [String] the field name in the search response data from Solr
    # @!attribute key
    #   @return [String] the field name as used in the application + user-facing HTML
    # @!attribute label
    #   @return [String, Symbol] the label or i18n key to use for labeling data from this field
    # @!attribute if
    #   @return [Proc, Symbol] a proc or the symbol name of a helper to test whether the field should be rendered.
    #     The helper or proc will receive this field configuration object as the first parameter. See Blacklight::Configuration::Context.
    # @!attribute unless
    #   @return [Proc, Symbol] a proc or the symbol name of a helper to test whether the field should not be rendered.
    #     The helper or proc will receive this field configuration object as the first parameter. See Blacklight::Configuration::Context.

    def normalize! _blacklight_config = nil
      self.field ||= key
      self.key ||= self.field

      self.label ||= default_label

      self.if = true if self.if.nil?
      self.unless = false if self.unless.nil?

      self.field &&= self.field.to_s

      self
    end

    def validate!
      raise ArgumentError, "Must supply a field name" if self.field.nil?
    end

    def display_label(context = nil, **options)
      field_label(
        (:"blacklight.search.fields.#{context}.#{key}" if context),
        :"blacklight.search.fields.#{key}",
        label,
        default_label,
        **options
      )
    end

    def default_label
      if self.key.respond_to?(:titleize)
        self.key.try(:titleize)
      else
        self.key.to_s.titleize
      end
    end

    private

    ##
    # Look up the label for a solr field.
    #
    # @overload label
    #   @param [Symbol] an i18n key
    #
    # @overload label, i18n_key, another_i18n_key, and_another_i18n_key
    #   @param [String] default label to display if the i18n look up fails
    #   @param [Symbol] i18n keys to attempt to look up
    #     before falling  back to the label
    #   @param [Symbol] any number of additional keys
    #   @param [Symbol] ...
    def field_label *i18n_keys, **options
      first, *rest = i18n_keys.compact

      I18n.t(first, default: rest, **options)
    end
  end
end
