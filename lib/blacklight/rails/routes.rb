module ActionDispatch::Routing
  class Mapper
    # example
    #   blacklight_for :catalog
    #   blacklight_for :catalog, :dashboard
    #   blacklight_for :catalog, except: [ :export, :feedback ]
    #   blacklight_for :catalog, only: [ :export, :solr_document ]
    #   blacklight_for :catalog, constraints: {id: /[0-9]+/ }
    def blacklight_for(*resources)
      options = resources.extract_options!
      resources.map!(&:to_sym)

      Blacklight::Routes.new(self, options.merge(resources: resources)).draw
    
    end
  end
end
