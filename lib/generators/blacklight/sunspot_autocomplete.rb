module Sunspot
  module Type
    
    #Auto Completion
    class AutocompleteType < AbstractType
      def indexed_name(name) #:nodoc:
        "#{name}_ac"
      end

      def to_indexed(value) #:nodoc:
        value.to_s if value
      end

      def cast(string) #:nodoc:
        string
      end
    end
    
    #Auto Suggestion
    class AutosuggestType < AbstractType
      def indexed_name(name) #:nodoc:
        "#{name}_as"
      end

      def to_indexed(value) #:nodoc:
        value.to_s if value
      end

      def cast(string) #:nodoc:
        string
      end
    end
    
    
  end
end