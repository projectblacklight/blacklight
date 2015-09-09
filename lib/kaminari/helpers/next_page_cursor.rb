require 'kaminari'

module Kaminari
  class Configuration
    config_accessor :cursor_param_name
  end

  configure do |config|
    config.cursor_param_name ||= :cursor
  end

  module Helpers
    class NextPageCursor < NextPage
      def initialize(*args)
        super
        @cursor_param_name = @options.delete(:cursor_param_name) || Kaminari.config.cursor_param_name
      end

      def page_url_for(*args)
        if cursor?
          @template.url_for @params.merge(@param_name => page, @cursor_param_name => cursor, :only_path => true)
        else
          super
        end
      end

      def cursor?
        cursor.present?
      end

      def cursor
        @options[:next_cursor_mark]
      end
    end

    class Paginator
      %w[next_page_cursor].each do |tag|
        eval <<-DEF
          def #{tag}_tag
            @last = #{tag.classify}.new @template, @options
          end
        DEF
      end
    end
  end
end