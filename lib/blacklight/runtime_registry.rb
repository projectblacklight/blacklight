# frozen_string_literal: true

module Blacklight
  class RuntimeRegistry
    thread_mattr_accessor :connection, :connection_config
  end
end
