module HtmlHeadHelper
  ##
  # This method should be included in any Blacklight layout, including
  # custom ones. It will output results of #render_js_includes,
  # #render_stylesheet_includes, and all the content of 
  # current_controller#extra_head_content.
  #
  # Uses controller methods #extra_head_content, #javascript_includes,
  # and #stylesheet_links to find content. Tolerates it if those
  # methods don't exist, silently skipping. 
  #
  # By a layout outputting this in html HEAD, it provides an easy way for
  # local config or extra plugins to add HEAD content.
  # 
  # Add your own css or remove the defaults by simply editing
  # controller.stylesheet_links, controller.javascript_includes,
  # or controller.extra_head_content. 
  #
  # 
  #
  # in an initializer or other startup file (plugin init.rb?):
  #
  # == Apply to all actions in all controllers:
  # 
  #   ApplicationController.before_filter do |controller|
  #     # remove default jquery-ui theme.
  #     controller.stylesheet_links.each do |args|
  #       args.delete_if {|a| a =~ /^|\/jquery-ui-[\d.]+\.custom\.css$/ }
  #     end
  # 
  #     # add in a different jquery-ui theme, or any other css or what have you
  #     controller.stylesheet_links << 'my_css.css'
  #
  #     controller.javascript_includes << "my_local_behaviors.js"
  #
  #     controller.extra_head_content << '<link rel="something" href="something">'
  #   end
  #
  # == Apply to a particular action in a particular controller:
  #
  #   CatalogController.before_filter :only => :show |controller|
  #     controller.extra_head_content << '<link rel="something" href="something">'
  #   end
  #
  # == Or in a view file that wants to add certain header content? no problem:
  #
  #   <%  stylesheet_links << "mystylesheet.css" %>
  #   <%  javascript_includes << "my_js.js" %>
  #   <%  extra_head_content << capture do %>
  #       <%= tag :link, { :href => some_method_for_something, :rel => "alternate" } %> 
  #   <%  end %>
  #
  # == Full power of javascript_include_tag and stylesheet_link_tag
  # Note that the elements added to stylesheet_links and javascript_links
  # are arguments to Rails javascript_include_tag and stylesheet_link_tag
  # respectively, you can pass complex arguments. eg:
  #
  # stylesheet_links << ["stylesheet1.css", "stylesheet2.css", {:cache => "mykey"}]
  # javascript_includes << ["myjavascript.js", {:plugin => :myplugin} ]
  def render_head_content
    render_stylesheet_includes +
    render_js_includes +
    render_extra_head_content
  end
  
  ##
  # Assumes controller has a #stylesheet_link_tag method, array with
  # each element being a set of arguments for stylesheet_link_tag
  # See #render_head_content for instructions on local code or plugins
  # adding stylesheets. 
  def render_stylesheet_includes
    return "".html_safe unless respond_to?(:stylesheet_links)
    
    stylesheet_links.uniq.collect do |args|
      stylesheet_link_tag(*args)
    end.join("\n").html_safe
  end
  

  ##
  # Assumes controller has a #js_includes method, array with each
  # element being a set of arguments for javsascript_include_tag.
  # See #render_head_content for instructions on local code or plugins
  # adding js files. 
  def render_js_includes
    return "".html_safe unless respond_to?(:javascript_includes)    
  
    javascript_includes.uniq.collect do |args|
      javascript_include_tag(*args)
    end.join("\n").html_safe
  end

  ## 
  # Assumes controller has a #extra_head_content method
  #
  def render_extra_head_content
    return "".html_safe unless respond_to?(:extra_head_content)

    extra_head_content.join("\n").html_safe
  end
end
