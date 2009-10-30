module NavigationHelpers
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
    
    when /the new user page/
      new_user_path
      
    when /the document page for id (.+)/ 
      catalog_path($1)
      
    when /the facet page for "([^\"]*)"/
      catalog_facet_path($1)
    
    # Add more page name => path mappings here
    
    else
      raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
        "Now, go and add a mapping in features/support/paths.rb"
    end
  end
end

# Cucumber 0.3
World(NavigationHelpers)

# Cucumber 0.2
=begin
World do |world|
  world.extend NavigationHelpers
  world
end
=end