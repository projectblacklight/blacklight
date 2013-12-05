##
# These controller methods are mixed into the ApplicationController, and 
# are likely things new Blacklight apps won't need (e.g. because of advancements in Rails)
# but are ideas that are firmly baked into existing application or plugins, so we're
# keeping around for now. There are probably better ways of doing some of the things 
# in here, but you may find them useful. 
module Blacklight
  module LegacyControllerMethods 
    
    protected
    #
    # If a param[:no_layout] is set OR
    # request.env['HTTP_X_REQUESTED_WITH']=='XMLHttpRequest'
    # don't use a layout, otherwise use the "application.html.erb" layout
    #
    def choose_layout
      layout_name unless request.xml_http_request? || ! params[:no_layout].blank?
    end
    
    #over-ride this one locally to change what layout BL controllers use, usually
    #by defining it in your own application_controller.rb
    def layout_name
      'blacklight'
    end
  end
end
