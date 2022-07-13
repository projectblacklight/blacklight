# frozen_string_literal: true

module Blacklight
  # This is a custom YAML coder for (de)serializing blacklight search parameters that
  # supports deserializing HashWithIndifferentAccess parameters (as was historically done by Blacklight).
  class SearchParamsYamlCoder
    # Serializes an attribute value to a string that will be stored in the database.
    def self.dump(obj)
      # Convert HWIA to an ordinary hash so we have some hope of using the regular YAML encoder in the future
      obj = obj.to_h if obj.is_a?(ActiveSupport::HashWithIndifferentAccess)

      YAML.dump(obj)
    end

    # Deserializes a string from the database to an attribute value.
    def self.load(yaml)
      return yaml unless yaml.is_a?(String) && yaml.start_with?("---")

      params = yaml_load(yaml)

      params.with_indifferent_access
    end

    # rubocop:disable Security/YAMLLoad
    if YAML.respond_to?(:unsafe_load)
      def self.yaml_load(payload)
        if ActiveRecord::Base.try(:use_yaml_unsafe_load)
          YAML.unsafe_load(payload)
        else
          YAML.safe_load(payload, permitted_classes: (ActiveRecord::Base.try(:yaml_column_permitted_classes) || []) + Blacklight::Engine.config.blacklight.search_params_permitted_classes, aliases: true)
        end
      end
    else
      def self.yaml_load(payload)
        if ActiveRecord::Base.try(:use_yaml_unsafe_load)
          YAML.load(payload)
        else
          YAML.safe_load(payload, permitted_classes: (ActiveRecord::Base.try(:yaml_column_permitted_classes) || []) + Blacklight::Engine.config.blacklight.search_params_permitted_classes, aliases: true)
        end
      end
    end
    # rubocop:enable Security/YAMLLoad
  end
end
