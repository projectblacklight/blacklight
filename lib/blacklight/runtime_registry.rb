# frozen_string_literal: true

require 'active_support/per_thread_registry'

module Blacklight
  class RuntimeRegistry
    extend ActiveSupport::PerThreadRegistry

    attr_accessor :connection, :connection_config
  end
end
