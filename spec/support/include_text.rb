# -*- encoding : utf-8 -*-
# Added from http://www.arctickiwi.com/blog/upgrading-to-rspec-2-with-ruby-on-rails-3
module RSpec::Rails
  module Matchers
    RSpec::Matchers.define :include_text do |text|
      match do |response_or_text|
        @content = response_or_text.respond_to?(:body) ? response_or_text.body : response_or_text
        @content.include?(text)
      end

      failure_message do |text|
        "expected '#{@content}' to contain '#{text}'"
      end

      failure_message_when_negated do |text|
        "expected #{@content} to not contain '#{text}'"
      end
    end
  end
end

