#
# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
#
class ApplicationController < ActionController::Base
  
  include SimplestAuth::Controller
  
  def user_class; User; end
  
  helper_method [:request_is_for_user_resource?]#, :user_logged_in?]
  #before_filter [:set_current_user, :restrict_user_access]
  
  helper :all # include all helpers, all the time
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '200c1e5f25e610288439b479ef176bbd'
  
  layout :choose_layout
  
  # test for exception notifier plugin
  def error
    raise RuntimeError, "Generating a test error..."
  end
  
  protected
    
    #
    # Controller and view helper for determining if the current url is a request for a user resource
    #
    def request_is_for_user_resource?
      request.env['PATH_INFO'] =~ /\/?users\/?/
    end
    
    #
    # If a param[:no_layout] is set OR
    # request.env['HTTP_X_REQUESTED_WITH']=='XMLHttpRequest'
    # don't use a layout, otherwise use the "application.html.erb" layout
    #
    def choose_layout
      'application' unless request.xml_http_request? || ! params[:no_layout].blank?
    end
    
=begin
    #
    # Sets the @current_user variable - this is the currently logged in user
    #
    def set_current_user
      @current_user = user_logged_in? ? User.find(session[:user_id]) : nil
    end
    
    
    
    #
    # Checks if the session[:user_id] value is set
    # if it is, verify that the id is valid
    #
    def user_logged_in?
      return false unless session[:user_id]
      return User.count(:conditions=>{:id=>session[:user_id]})==1
    end
    
    #
    # checks to see if the url is a user resource (/users*)
    # if it is a user resource
    # and the @current_user is set
    # and the @current_user's id does NOT match the url user id
    # redirect to the catalog page
    #
    def restrict_user_access
      return unless request_is_for_user_resource?
      
      # we are now working with a user related resource...
      
      # if the user is not logged in and the current controller is NOT /sessions
      # redirect to the /sessions controller
      #if ! user_logged_in? and (params[:controller]!='sessions' and params[:action]!='index')
      #  redirect_to sessions_path
      #end
      
      #
      # If the controller is "users" the user id is params[:id]
      # if the controller is a parent controller of a user (users/1/bookmarks)
      # then the user id is params[:user_id] - this nested behavior comes from ResourceController:
      # http://github.com/giraffesoft/resource_controller/tree/master
      #
      uid = params[:controller]=='users' ? params[:id] : params[:user_id]
      
      # redirect if the request user id does not match the session user id and a user resource is being requested
      if @current_user and uid and (uid.to_s != @current_user.id.to_s)
        # don't allow access to this resource, it doesn't belong to the user...
        redirect_to catalog_index_path
      end
    end
    
    # built-in Rails hook for rescuing errors in "public" (production mode)
    # NOTE: overriding this method will actually override ExceptionNotifier == no exception mail gets sent
    # The solution is to override the render_404 and render_500 method (see below)
    #def rescue_action_in_public(exception)
    #  render :template=>'error'
    #end
    
    # called by ExceptionNotifiable (see vendor/plugins/exception_notification)
    def render_404
      respond_to do |type|
        type.html { render :template=>'error', :status => "404 Not Found" }
        type.all  { render :nothing => true, :status => "404 Not Found" }
      end
    end
    
    # called by ExceptionNotifiable (see vendor/plugins/exception_notification)
    def render_500
      respond_to do |type|
        type.html { render :template=>'error', :status => "599 Error" }
        type.all  { render :nothing => true, :status => "500 Error" }
      end
    end
=end
end
