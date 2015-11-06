module Blacklight
  module Solr
    require File.join(Blacklight::Engine.config.root, 'app', 'models', 'concerns', 'blacklight', 'document')
    require File.join(Blacklight::Engine.config.root, 'app', 'models', 'concerns', 'blacklight', 'solr', 'document')

    autoload :Repository, 'blacklight/solr/repository'
    autoload :Request, 'blacklight/solr/request'
    autoload :Response, 'blacklight/solr/response'
    autoload :SearchBuilderBehavior, 'blacklight/solr/search_builder_behavior'
  end
end
