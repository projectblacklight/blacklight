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
    
    # Add more page name => path mappings here
    
    else
      raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
        "Now, go and add a mapping in features/support/paths.rb"
    end
  end
end

World do |world|
  world.extend NavigationHelpers
  world
end
