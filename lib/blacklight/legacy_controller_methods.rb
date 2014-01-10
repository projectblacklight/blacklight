##
# These controller methods are mixed into the ApplicationController, and 
# are likely things new Blacklight apps won't need (e.g. because of advancements in Rails)
# but are ideas that are firmly baked into existing application or plugins, so we're
# keeping around for now. There are probably better ways of doing some of the things 
# in here, but you may find them useful. 
module Blacklight
  module LegacyControllerMethods 
    extend ActiveSupport::Concern

    extend Deprecation
    self.deprecation_horizon = 'Blacklight 5.x'


    included do

      before_filter :default_html_head_without_deprecation # add JS/stylesheet stuff

      helper_method :extra_head_content, :stylesheet_links, :javascript_includes
    end

    #############
    # Display-related methods.
    #############
    
    # before filter to set up our default html HEAD content. Sub-class
    # controllers can over-ride this method, or instead turn off the before_filter
    # if they like. See:
    # http://api.rubyonrails.org/classes/ActionController/Filters/ClassMethods.html
    # for how to turn off a filter in a sub-class and such.
    def default_html_head
      Deprecation.warn Blacklight::LegacyControllerMethods, "#default_html_head is deprecated"
    end
    
    def default_html_head_without_deprecation
      Deprecation.silence(Blacklight::LegacyControllerMethods) do
        default_html_head
      end
    end
    
    # An array of strings to be added to HTML HEAD section of view.
    # See ApplicationHelper#render_head_content for details.
    def extra_head_content
      Deprecation.warn Blacklight::LegacyControllerMethods, "#extra_head_content is deprecated"

      @extra_head_content ||= []
    end

    # Array, where each element is an array of arguments to
    # Rails stylesheet_link_tag helper. See
    # ApplicationHelper#render_head_content for details.
    def stylesheet_links
      Deprecation.warn Blacklight::LegacyControllerMethods, "#stylesheet_links is deprecated"

      @stylesheet_links ||= []
    end
    
    # Array, where each element is an array of arguments to
    # Rails javascript_include_tag helper. See
    # ApplicationHelper#render_head_content for details.
    def javascript_includes
      Deprecation.warn Blacklight::LegacyControllerMethods, "#javascript_includes is deprecated"

      @javascript_includes ||= []
    end
    
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
