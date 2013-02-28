# -*- encoding : utf-8 -*-
# Copy Blacklight test support material in place


# Need the requires here so we can call the generator from environment.rb
# as suggested above. 
require 'rails/generators'
require 'rails/generators/base'
module Blacklight
  class TestSupport < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
  desc """ 
Installs a jetty container with a solr installed in it. A solr setup known 
good with default blacklight setup, including solr conf files for out
of the box blacklight. 

Also adds jetty_path key to solr.yml for selected environment, to refer
to this install. 

Requires system('unzip... ') to work, probably won't work on Windows.

"""
    def alternate_controller
      copy_file "alternate_controller.rb", "app/controllers/alternate_controller.rb"

      route("resources :alternate do
                member do
                  get :facet
                end
              end")


    end

    def configure_action_mailer

      if Rails::VERSION::MAJOR == 4
      insert_into_file "config/environments/test.rb", :after => "config.action_mailer.delivery_method = :test\n" do <<EOF
    config.action_mailer.default_options = {from: 'no-reply@example.org'}
EOF
else
 insert_into_file "config/environments/test.rb", :after => "config.action_mailer.delivery_method = :test\n" do <<EOF
    ActionMailler::Base.default(from: 'no-reply@example.org')
EOF
  end
      end
    end
  end
end
