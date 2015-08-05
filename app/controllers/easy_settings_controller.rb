# edit and update actions are for a plugin settings
# it uses a presenter, wich prefixes the settings name by a plugin id automatically
class EasySettingsController < ApplicationController

  before_filter :find_optional_project, only: [:edit, :update]
  before_filter :prepare_presenter

  def new
  end

  def create
    if @settings.save
      redirect_to :back
    else
      render :new
    end
  end

  def edit
    @settings.plugin = Redmine::Plugin.find(params[:id])
  end

  def update
    @settings.plugin = Redmine::Plugin.find(params[:id])
    if @settings.save
      redirect_to redmine_extensions_engine.edit_easy_setting_path(@settings)
    else
      render :edit
    end
  end

  private
    def find_optional_project
      @project = Project.find(params[:project_id]) unless params[:project_id].blank?
    end

    def prepare_presenter
      @settings = RedmineExtensions::EasySettingsPresenter.new(params[:easy_setting], @project)
    end

end
