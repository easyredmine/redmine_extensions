class EasyQueriesController < ApplicationController

  def new
    @query = params[:type].constantize
  end

end
