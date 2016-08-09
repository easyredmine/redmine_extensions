# Engine routes
RedmineExtensions::Engine.routes.draw do
  resources :easy_settings, except: :destroy
end

# Redmine routes
Rails.application.routes.draw do
  mount RedmineExtensions::Engine => '/redmine_extensions'

  resources :easy_settings, except: :destroy
end
