# frozen_string_literal: true
Blacklight::Engine.routes.draw do
  get "search_history",             to: "search_history#index",   as: "search_history"
  delete "search_history/clear",       to: "search_history#clear",   as: "clear_search_history"
end
