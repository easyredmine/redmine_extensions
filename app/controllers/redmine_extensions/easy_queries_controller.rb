require_dependency "redmine_extensions/application_controller"

module RedmineExtensions
  class EasyQueriesController < ApplicationController

    def new
      @query = params[:type].constantize
    end

  end
end
