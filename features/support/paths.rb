module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name

      when /the home page/
        root_path

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

      when /the unAPI endpoint/
        unapi_path

      when /the unAPI endpoint for ""/

      when /the unAPI endpoint for "" with format ""/


      # Add more page name => path mappings here

      else
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
          "Now, go and add a mapping in features/support/paths.rb"
      end
  end
end

World(NavigationHelpers)
