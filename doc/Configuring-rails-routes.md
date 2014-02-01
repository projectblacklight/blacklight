If your solr ids happen to have dots in them, Rails is going interpret the dots as the separator between the file name and the file exension, and your documents won't be displayed on the show view.  In order to fix that you can override the default routes like this:

```ruby
ALLOW_DOTS ||= /[a-zA-Z0-9_.:]+/
MyApp::Application.routes.draw do
  root :to => "catalog#index"
  ...
  resources :catalog, :only => [:show, :update], :constraints => { :id => ALLOW_DOTS, :format => false }
  Blacklight::Routes.new(self, {}).catalog
end
```

you must put the line defining the route with the constraints before you call Blacklight::Routes because the first route that matches is the one that will be used.