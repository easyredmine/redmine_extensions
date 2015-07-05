Rails.application.routes.draw do

  mount RedmineExtensions::Engine => "/redmine_extensions"
end
