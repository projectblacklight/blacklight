module Blacklight
  module Solr
    require File.join(Blacklight::Engine.config.root, 'app', 'models', 'concerns', 'blacklight', 'document')
    require File.join(Blacklight::Engine.config.root, 'app', 'models', 'concerns', 'blacklight', 'solr', 'document')
  end
end
