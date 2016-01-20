require 'rails/generators'

module Blacklight
  class Solr5Generator < Rails::Generators::Base
    desc <<-EOF
      This generator makes the following changes to your application:
       1. Installs solr_wrapper into your application
       2. Adds rsolr to your Gemfile
    EOF

    def install_solrwrapper
      gem 'solr_wrapper', '>= 0.3'

      append_to_file "Rakefile", "\nrequire 'solr_wrapper/rake_task'\n"
    end

    def add_rsolr_gem
      gem 'rsolr', '~> 1.0.6'
    end
  end
end
