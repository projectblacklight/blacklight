ActionController::Routing::Routes.draw do |map|
  
  # to build Blacklight routes, pass the map object to the build method.
  # only build the routes if the plugin is running as the app.
  Blacklight::Routes.build(map) if Rails.root.to_s == Blacklight.root.to_s
  
end