# frozen_string_literal: true
module Blacklight
  unless Blacklight.const_defined? :VERSION
    def self.version
      @version ||= File.read(File.join(File.dirname(__FILE__), '..', '..', 'VERSION')).chomp
    end

    VERSION = version
  end
end
