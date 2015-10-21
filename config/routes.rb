RedmineExtensions::Engine.routes.draw do
  resources :easy_queries do
    get 'filters', on: :collection
    get 'load_users_for_copy'
  end

  resources :easy_settings, except: :destroy

end

RedmineExtensions::Engine.automount!
