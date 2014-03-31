module ActionDispatch::Routing
  class Mapper
    # example
    #   blacklight_for :catalog
    #   blacklight_for :catalog, :dashboard
    #   blacklight_for :catalog, except: [ :saved_searches ]
    #   blacklight_for :catalog, only: [ :saved_searches, :solr_document ]
    #   blacklight_for :catalog, constraints: {id: /[0-9]+/ }
    def blacklight_for(*resources)
      raise_no_secret_key unless Blacklight.secret_key
      options = resources.extract_options!
      resources.map!(&:to_sym)

      Blacklight::Routes.new(self, options.merge(resources: resources)).draw
    
    end
    
    private
    def raise_no_secret_key #:nodoc:
      raise <<-ERROR
Blacklight.secret_key was not set. Please add the following to an initializer:

Blacklight.secret_key = '#{SecureRandom.hex(64)}'

Please ensure you restarted your application after installing Blacklight or setting the key.
ERROR
    end
  end
end
