# frozen_string_literal: true
Blacklight::Engine.routes.draw do
  get "search_history",             :to => "search_history#index",   :as => "search_history"
  delete "search_history/clear",       :to => "search_history#clear",   :as => "clear_search_history"
  delete "saved_searches/clear",       :to => "saved_searches#clear",   :as => "clear_saved_searches"
  get "saved_searches",       :to => "saved_searches#index",   :as => "saved_searches"
  put "saved_searches/save/:id",    :to => "saved_searches#save",    :as => "save_search"
  delete "saved_searches/forget/:id",  :to => "saved_searches#forget",  :as => "forget_search"
  post "saved_searches/forget/:id",  :to => "saved_searches#forget"
  post "/catalog/:id/track", to: 'catalog#track', as: 'track_search_context'

  resources :suggest, only: :index, defaults: { format: 'json' }
end
