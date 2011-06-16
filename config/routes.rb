# -*- encoding : utf-8 -*-
Rails.application.routes.draw do
  # A Note on User Sessions:
  # Blacklight expects the following named routes or at least the associated path helper methods to be defined.
  # new_user_session   (for logging in) - pages that require a log in will redirect users here.
  # destroy_user_session (for logging out)

  # Routes for the Blacklight application are defined in Blacklight::Routes
  #
  # These routes can be injected into your Rails application by adding
  #     Blacklight.add_routes(self)
  # to the application's ./config/routes.rb. The injected routes can be 
  # customized as well, e.g.:
  #     Blacklight.add_routes(self, :only => [:bookmarks]) # will only look bookmark routes
  #     Blacklight.add_routes(self, :except => [:catalog]) # will not load catalog routes
end

