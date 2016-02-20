# frozen_string_literal: true
require 'rails/generators'

module Blacklight
  class Solr4Generator < Rails::Generators::Base
    desc """
This generator makes the following changes to your application:
 1. Installs jettywrapper into your application
 2. Adds rsolr to your Gemfile
"""

    def install_jettywrapper
      return unless options[:jettywrapper]
      gem "jettywrapper".dup, ">= 2.0"

      copy_file "config/jetty.yml"

      append_to_file "Rakefile",
        "\nZIP_URL = \"https://github.com/projectblacklight/blacklight-jetty/archive/v4.10.4.zip\"\n" +
        "require 'jettywrapper'\n"
    end

    def add_rsolr_gem
      gem "rsolr".dup, "~> 1.0.6"
    end

  end
end
