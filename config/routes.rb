RedmineExtensions::Engine.routes.draw do
  resources :easy_queries do
    get 'filters', on: :collection
  end

  resources :easy_settings, except: :destroy
end

RedmineExtensions::Engine.automount!
