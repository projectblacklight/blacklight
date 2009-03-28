#
#
# Be sure to add this to functional tests:
# * @request.cookies['_session_id'] = 'fake cookie bypasses filter'
#
# usage:
#
# class MyController < ApplicationController
#   extend CookiesRequired
#   cookies_required
# end
#
module CookiesRequired
  
  def self.extended(base)
    base.send :include, InstanceMethods
  end
  
  #
  # Possible options are:
  # * :controller - the path of the controller running this code (not including action)
  # * :template - the template to display if the user doesn't have cookies enabled
  # * :success_redirect_to - if cookies are enabled, redirect to this path
  # Can also use a block
  #
  def cookies_required(options={}, &block)
    options[:controller]||=self.to_s.sub(/Controller$/, '').underscore
    options[:template]||=options[:controller] + '/cookies_required'
    self.before_filter do |controller|
      controller.instance_variable_set('@cookies_required_options', options)
      yield options, controller
    end
    before_filter :cookies_required!, :except => :cookies_test
  end
  
  module InstanceMethods
    
    #
    #
    #
    def cookies_required!
      #
      # config.action_controller.session[:session_key] ???
      #
      if request.cookies.to_s.blank?
        session[:return_to] = request.request_uri
        redirect_to(:controller => @cookies_required_options[:controller], :action => :cookies_test)
        return false
      end
    end
    
    #
    #
    #
    def cookies_test
      if request.cookies.to_s.blank?
        logger.warn('=== cookies are disabled')
        render :template => @cookies_required_options[:template]
      else
        raise 'Please specify a :success_redirect_to - example -> cookies_required(:success_redirect_to=>"/success.html")' unless @cookies_required_options[:success_redirect_to]
        redirect_to(*@cookies_required_options[:success_redirect_to])
      end
    end
    
  end
  
end