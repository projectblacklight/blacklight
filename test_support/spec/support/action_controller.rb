# -*- encoding : utf-8 -*-
# Added based on http://www.arctickiwi.com/blog/upgrading-to-rspec-2-with-ruby-on-rails-3
# God bless you Jonathon Horsman 
module ActionController
  class TestCase < ActiveSupport::TestCase
    module Behavior
      def process(action, parameters = nil, session = nil, flash = nil, http_method = 'GET')
        # Sanity check for required instance variables so we can give an
        # understandable error message.
        %w(@routes @controller @request @response).each do |iv_name|
          if !(instance_variable_names.include?(iv_name) || instance_variable_names.include?(iv_name.to_sym)) || instance_variable_get(iv_name).nil?
            raise "#{iv_name} is nil: make sure you set it in your test's setup method."
          end
        end
        
        @request.recycle!
        @response.recycle!
        @controller.response_body = nil
        @controller.formats = nil
        @controller.params = nil
        
        @html_document = nil
        @request.env['REQUEST_METHOD'] = http_method
        
        parameters ||= {}
        @request.assign_parameters(@routes, @controller.class.name.underscore.sub(/_controller$/, ''), action.to_s, parameters)
        
        @request.session = ActionController::TestSession.new(session) unless session.nil?
        @request.session["flash"] = @request.flash.update(flash || {})
        @request.session["flash"].sweep
        
        @controller.request = @request
        #@controller.params.merge!(parameters) # this is the offending line, which I removed
        build_request_uri(action, parameters)
        Base.class_eval { include Testing }
        @controller.process_with_new_base_test(@request, @response)
        @request.session.delete('flash') if @request.session['flash'].blank?
        @response
      end
    end
  end
end

