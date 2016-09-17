# frozen_string_literal: true
# Copy Blacklight test support material in place

# Need the requires here so we can call the generator from environment.rb
# as suggested above.
require 'rails/generators'
require 'rails/generators/base'
module Blacklight
  class TestSupport < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    desc <<-EOS
      Generate blacklight testing configurations for blacklight's own tests, or for blacklight plugins to use for testing
    EOS

    def alternate_controller
      copy_file "alternate_controller.rb", "app/controllers/alternate_controller.rb"

      routing_code = <<-EOF.strip_heredoc
        resource :alternate, controller: 'alternate', only: [:index] do
          concerns :searchable
        end
      EOF

      sentinel = /concern :searchable[^\n]+\n/

      inject_into_file 'config/routes.rb', routing_code, { after: sentinel, force: true }
    end

    def solr_document_config
      insert_into_file 'app/models/solr_document.rb', after: "include Blacklight::Solr::Document" do
        <<-EOF

            field_semantics.merge!(
              title: "title_display",
              author: "author_display",
              language: "language_facet",
              format: "format")
        EOF
      end
    end

    def configure_action_mailer
      insert_into_file "config/environments/test.rb", :after => "config.action_mailer.delivery_method = :test\n" do <<-EOF
         config.action_mailer.default_options = {from: 'no-reply@example.org'}
      EOF
      end
    end
  end
end
