RedmineExtensions::Engine.routes.draw do
  resources :easy_queries
end

RedmineExtensions::Engine.automount!
