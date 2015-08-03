module RedmineExtensions
  class ApplicationController < ::ApplicationController
    delegate :signin_url, :signin_path, to: :main_app

  end
end
