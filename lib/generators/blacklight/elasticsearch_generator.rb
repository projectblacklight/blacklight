require 'rails/generators'

module Blacklight
  class ElasticsearchGenerator < Rails::Generators::Base
    source_root ::File.expand_path('../templates', __FILE__)

    desc <<-EOF
      This generator makes the following changes to your application:
       1. Adds elasticsearch gems to your Gemfile
    EOF

    def add_gems
      gem 'elasticsearch-model'
      gem 'elasticsearch-rails'
      gem 'elasticsearch-persistence'
    end
  end
end
