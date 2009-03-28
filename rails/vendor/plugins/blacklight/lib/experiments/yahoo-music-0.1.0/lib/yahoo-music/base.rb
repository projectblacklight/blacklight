module Yahoo
  module Music
    class Base
      class << self
        attr_accessor   :attributes, :associations
        cattr_accessor  :connection
        
        def attribute(*args)
          @attributes   ||= {}
          @associations ||= []
          
          options = args.extract_options!
          name, type = args
          class_eval %(attr_accessor :#{name})
          @attributes[name] = options.update({:type => type})
          
          if Yahoo::Music::Base.subclasses.include?(type.inspect)
            @associations << name
            
            # Define plural and singular association methods
            define_method("#{name}".pluralize.to_sym) do
              value = instance_variable_get("@#{name}") || query_association_by_id(name, self.id)
              instance_variable_set("@#{name}", value)
              return value
            end
            
            define_method("#{name}".singularize.to_sym) do
              value = instance_variable_get("@#{name}") || query_association_by_id(name, self.id)
              value = value.first
              instance_variable_set("@#{name}", value)
              return value
            end
          end
          
          if options[:type] == Boolean
            define_method("#{name}?".to_sym) do
              value = instance_variable_get("@#{name}")
              return value
            end
          end
        end
        
        def attributes
          @attributes || {}
        end
        
        def associations
          @associations || []
        end
        
        def name_with_demodulization
          self.name_without_demodulization.demodulize        
        end
        
        alias_method_chain :name, :demodulization

        def fetch_and_parse(resource, options = {})      
          raise YahooWebServiceError, "No App ID specified" if connection.nil?    
          options = options.update({'response' => self.associations.join(',')}) if self.associations.any?
          return Hpricot::XML(connection.get(resource, options))
        end
        
        def api_path(service, resource, method, *args)
          response_type = method.nil? ? :item : :list
          parameters = [service, API_VERSION, response_type, resource, method, *args].compact
          return parameters.collect!{|param| CGI::escape(param.to_s).downcase}.join('/')
        end
        
        # Search by a parameter for a specific service
        # Ex. Artist.search(term)
        # options[:search_mode]
        def search(*args)
          options = args.extract_options!
          xml = fetch_and_parse(api_path(self.name, nil, :search, options[:search_mode] || :all, args.join(',')), options)
          return xml.search(self.name).collect{|elem| self.new(elem)}
        end
      end
            
      def initialize(xml)
        raise ArgumentError unless xml.kind_of?(Hpricot)
                
        self.class.attributes.each do |attribute, options|
          value = xml.attributes[options[:matcher] || attribute.to_s]
          begin
            if options[:type] == Integer
              value = value.to_i
            elsif options[:type] == Float
              value = value.to_f
            elsif options[:type] == Date
              value = Date.parse(value) rescue nil
            elsif options[:type] == Boolean
              value = !! value.to_i.nonzero?
            elsif self.class.associations.include?(attribute)
              klass = options[:type]
              value = xml.search(klass.name).collect{|elem| klass.new(elem)}
              value = nil if value.empty?
            end
          ensure
            self.instance_variable_set("@#{attribute}", value)
          end     
        end        
      end
      
      def initialize_with_polymorphism(arg)
        case arg
        when String
          initialize_without_polymorphism(query_by_string(arg))
        when Integer
          initialize_without_polymorphism(query_by_id(arg))
        when Hpricot
          initialize_without_polymorphism(arg)
        end
      end
     
      alias_method_chain :initialize, :polymorphism
      
    protected
      def query_by_id(id)
        xml = self.class.fetch_and_parse(self.class.api_path(self.class.name, nil, nil, id))
        return xml.at(self.class.name)
      end
      
      def query_by_string(string)
        xml = self.class.fetch_and_parse(self.class.api_path(self.class.name, nil, :search, :all, string ))
        return xml.at(self.class.name)
      end   
      
      def query_association_by_id(association, id)
        klass = "yahoo/music/#{association.to_s.singularize}".camelize.constantize
        xml = self.query_by_id(id).search(klass.name)
        return xml.collect{|elem| klass.new(elem)}
      end   
    end
  
    class YahooWebServiceError < StandardError; end
  
    class Artist    < Base; end
    class Category  < Base; end
    class Image     < Base; end
    class Release   < Base; end
    class Review     < Base; end
    class Track     < Base; end
    class Video     < Base; end
    
  end
end

class Boolean; end