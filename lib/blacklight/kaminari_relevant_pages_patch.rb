module Blacklight
  module KaminariRelevantPagesPatch
    module Windows
      def relevant_pages options
        [left_window(options), inside_window(options), right_window(options)].map(&:to_a).flatten.uniq.sort.reject { |x| x < 1 or x > options[:num_pages] }
      end

      def all_pages options
        1.upto(options[:num_pages])
      end

      protected
      def left_window options
        1.upto(options[:left] + 1)
      end

      def right_window options
        (options[:num_pages] - options[:right]).upto(options[:num_pages])
      end

      def inside_window options
        (options[:current_page] - options[:window]).upto(options[:current_page] + options[:window])
      end
    end

    include Windows
    def each_relevant_page
      return to_enum(:each_relevant_page) unless block_given?

      relevant_pages(@window_options.merge(@options)).each do |i|
        yield Kaminari::Helpers::Paginator::PageProxy.new(@window_options.merge(@options), i, @last)
      end
    end
  end
end

Kaminari::Helpers::Paginator.send(:include, Blacklight::KaminariRelevantPagesPatch)
