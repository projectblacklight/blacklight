# -*- encoding : utf-8 -*-
module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name

    when /the home\s?page/
      '/'

      
    when /the catalog page/
      catalog_index_path
      
    when /the folder page/
      folder_index_path
         
    when /the document page for id (.+)/ 
      catalog_path($1)
      
    when /the facet page for "([^\"]*)"/
      catalog_facet_path($1)

    when /the unAPI endpoint for "([^\"]+)" with format "([^\"]+)"/
      unapi_path(:id => $1, :format => $2)

    when /the unAPI endpoint for "([^\"]+)"/
      unapi_path(:id => $1)

    when /the unAPI endpoint/
      unapi_path

    # Add more mappings here.
    # Here is an example that pulls values out of the Regexp:
    #
    #   when /^(.*)'s profile page$/i
    #     user_profile_path(User.find_by_login($1))

    else
      begin
        page_name =~ /the (.*) page/
        path_components = $1.split(/\s+/)
        self.send(path_components.push('path').join('_').to_sym)
      rescue Object => e
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
          "Now, go and add a mapping in #{__FILE__}"
      end
    end
  end
end

World(NavigationHelpers)
