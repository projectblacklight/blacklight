module Blacklight
  class Configuration

    # This mixin provides Blacklight::Configuration with generic
    # solr fields configuration
    module Fields
      extend ActiveSupport::Concern

      module ClassMethods

        # Add a configuration block for a collection of solr fields
        def define_field_access(key)
          key = key.to_s if respond_to? :to_s

          self.default_values[key.pluralize.to_sym] = ActiveSupport::OrderedHash.new

          unless self.const_defined? key.camelcase
            class_eval <<-END_EVAL, __FILE__, __LINE__ + 1
              class #{key.camelcase} < SolrField; end
            END_EVAL
          end
    
          class_eval <<-END_EVAL, __FILE__, __LINE__ + 1
            def add_#{key}(*args, &block)
              add_solr_field("#{key}", *args, &block)
            end
          END_EVAL
        end
      end

      # Add a solr field configuration to the given configuration key
      #
      # The recommended and strongly encouraged format is a field name, configuration pair, e.g.:
      #     add_solr_field :index_field, 'format', :label => 'Format' 
      #
      # Alternative formats include:
      #
      # * a field name and block format:
      #
      #     add_solr_field :index_field, 'format' do |field|
      #       field.label = 'Format'
      #     end
      #
      # * a plain block:
      #
      #     add_solr_field :index_field do |field|
      #       field.field = 'format'
      #       field.label = 'Format'
      #     end
      # 
      # * a configuration hash:
      #
      #     add_solr_field :index_field, :field => 'format', :label => 'Format'
      #   
      # * a Field instance: 
      #
      #     add_solr_field :index_field, IndexField.new(:field => 'format', :label => 'Format')
      #
      # * an array of hashes: 
      #
      #     add_solr_field :index_field, [{:field => 'format', :label => 'Format'}, IndexField.new(:field => 'date', :label => 'Date')]
      #
      #
      # @param String config_key 
      # @param Array *args 
      # @para
      #
      def add_solr_field config_key, *args, &block
        field_config = case args.first
          when String
            field_config_from_key_and_hash(config_key, *args)
          when Symbol
            args[0] = args[0].to_s
            field_config_from_key_and_hash(config_key, *args)
          when Array
            field_config_from_array(config_key, *args)
          else
            field_config_from_field_or_hash(config_key, *args)
        end

        return if field_config.is_a? Array
  
        if block_given?
          yield field_config
        end
            
        field_config.normalize!(self)
        field_config.validate!

        raise "A #{config_key} with the key #{field_config.field} already exists." if self[config_key.pluralize][field_config.field].present?

        self[config_key.pluralize][ field_config.field ] = field_config            
      end

      protected
      # Add a solr field by a solr field name and hash 
      def field_config_from_key_and_hash config_key, solr_field, field_or_hash = {}
        field_config = field_config_from_field_or_hash(config_key, field_or_hash)
        field_config.field = solr_field

        field_config
      end

      # Add multiple solr fields using a hash or Field instance
      def field_config_from_array config_key, array_of_fields_or_hashes
        array_of_fields_or_hashes.map do |field_or_hash| 
          add_solr_field(config_key, field_or_hash)
        end
      end

      # Add a solr field using a hash or Field instance
      def field_config_from_field_or_hash config_key, field_or_hash = {}
        hash_arg_to_config(field_or_hash, field_class_from_key(config_key))
      end

      # for our add_* methods, takes the optional hash param,
      # and makes it into a specific config OpenStruct, like
      # FacetField or SearchField. Or if the param already was
      # one, that's cool. Or if the param is nil, make
      # an empty one. Second argument is an actual class object. 
      def hash_arg_to_config(hash_arg, klass)
        case hash_arg
        when Hash 
          klass.new(hash_arg)
        when NilClass 
          klass.new
        else 
          # this assumes it already is an element of klass, or acts like one,
          # if not something bad will happen later, that's your problem. 
          hash_arg
        end
      end

      private
      # convert a config key to the appropriate Field class
      def field_class_from_key key
        "Blacklight::Configuration::#{key.camelcase}".constantize
      end
    end
  end
end
