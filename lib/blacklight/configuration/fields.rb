module Blacklight
  class Configuration
    # This mixin provides Blacklight::Configuration with generic
    # solr fields configuration
    module Fields
      extend ActiveSupport::Concern
      extend Deprecation
      self.deprecation_horizon = "blacklight 6.0"

      module ClassMethods

        # Add a configuration block for a collection of solr fields
        def define_field_access(key, options = {})
          key = key.to_s if respond_to? :to_s

          self.default_values[key.pluralize.to_sym] = ActiveSupport::OrderedHash.new

          base_class_name = options.fetch(:class, Field)

          unless self.const_defined? key.camelcase
            class_eval <<-END_EVAL, __FILE__, __LINE__ + 1
              class #{key.camelcase} < #{base_class_name}; end
            END_EVAL
          end
    
          class_eval <<-END_EVAL, __FILE__, __LINE__ + 1
            def add_#{key}(*args, &block)
              add_blacklight_field("#{key}", *args, &block)
            end
          END_EVAL
        end
      end

      # Add a solr field configuration to the given configuration key
      #
      # The recommended and strongly encouraged format is a field name, configuration pair, e.g.:
      #     add_blacklight_field :index_field, 'format', :label => 'Format' 
      #
      # Alternative formats include:
      #
      # * a field name and block format:
      #
      #     add_blacklight_field :index_field, 'format' do |field|
      #       field.label = 'Format'
      #     end
      #
      # * a plain block:
      #
      #     add_blacklight_field :index_field do |field|
      #       field.field = 'format'
      #       field.label = 'Format'
      #     end
      # 
      # * a configuration hash:
      #
      #     add_blacklight_field :index_field, :field => 'format', :label => 'Format'
      #   
      # * a Field instance: 
      #
      #     add_blacklight_field :index_field, IndexField.new(:field => 'format', :label => 'Format')
      #
      # * an array of hashes: 
      #
      #     add_blacklight_field :index_field, [{:field => 'format', :label => 'Format'}, IndexField.new(:field => 'date', :label => 'Date')]
      #
      #
      # @param String config_key 
      # @param Array *args 
      # @para
      #
      def add_blacklight_field config_key, *args, &block
        field_config = case args.first
          when String
            field_config_from_key_and_hash(config_key, *args)
          when Symbol
            args[0] = args[0].to_s
            field_config_from_key_and_hash(config_key, *args)
          when Array
            field_config_from_array(config_key, *args, &block)
            return # we've iterated over the array above.
          else
            field_config_from_field_or_hash(config_key, *args)
        end

        # look up any dynamic fields
        if field_config.field.to_s =~ /\*/ and luke_fields
          salient_fields = luke_fields.select do |k,v| 
            k =~ Regexp.new("^" + field_config.field.to_s.gsub('*', '.+') + "$")
          end

          salient_fields.each do |field, luke_config|
            config = field_config.dup
            config.field = field
            if self[config_key.pluralize][ config.field ]
              self[config_key.pluralize][ config.field ] = config.merge(self[config_key.pluralize][ config.field ])
            else
              add_blacklight_field(config_key, config, &block)
            end
          end

          return
        end
  
        if block_given?
          yield field_config
        end
            
        field_config.normalize!(self)
        field_config.validate!

        raise "A #{config_key} with the key #{field_config.field} already exists." if self[config_key.pluralize][field_config.field].present?

        self[config_key.pluralize][ field_config.field ] = field_config            
      end
      alias_method :add_solr_field, :add_blacklight_field
      deprecation_deprecate :add_solr_field

      protected
      def luke_fields
        if @table[:luke_fields] === false
          return nil
        end

        @table[:luke_fields] ||= begin
          if has_key? :blacklight_solr
            blacklight_solr.get('admin/luke', params: { fl: '*', 'json.nl' => 'map' })['fields']
          end
        rescue
          false
        end

        @table[:luke_fields] || nil
      end

      # Add a solr field by a solr field name and hash 
      def field_config_from_key_and_hash config_key, field_name, field_or_hash = {}
        field_config = field_config_from_field_or_hash(config_key, field_or_hash)
        field_config.field = field_name

        field_config
      end

      # Add multiple solr fields using a hash or Field instance
      def field_config_from_array config_key, array_of_fields_or_hashes, &block
        array_of_fields_or_hashes.map do |field_or_hash| 
          add_blacklight_field(config_key, field_or_hash, &block)
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
