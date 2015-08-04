RedmineExtensions::Engine.routes.draw do
  resources :easy_queries

  resources :easy_settings, except: :destroy
end

RedmineExtensions::Engine.automount!
