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
      
    when /the search history page/
      search_history_index_path
      
    when /the saved searches page/
      saved_searches_path
      
    when /the bookmarks page/
      bookmarks_path
      
    when /the login page/
      login_path
      
    when /the folder page/
      folder_index_path
      
    when /the new user page/
      new_user_path
      
    when /the user profile page/
      user_path
      
    when /the document page for id (.+)/ 
      catalog_path($1)
      
    when /the facet page for "([^\"]*)"/
      catalog_facet_path($1)
      
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
