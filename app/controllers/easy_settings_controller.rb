# edit and update actions are for a plugin settings
# it uses a presenter, wich prefixes the settings name by a plugin id automatically
class EasySettingsController < ApplicationController

  before_filter :find_optional_project
  before_filter :prepare_presenter
  before_filter :find_plugin, only: [:edit, :update]

  def new
  end

  def create
    if @easy_settings.save
      redirect_to :back
    else
      render :new
    end
  end

  def edit
    @settings = Setting.send "plugin_#{@plugin.id}"
  end

  def update
    Setting.send "plugin_#{@plugin.id}=", params[:settings] if params[:settings]
    if @easy_settings.save
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default edit_easy_setting_path(@easy_settings)
    else
      render :edit
    end
  end

  private
    def find_optional_project
      @project = Project.find(params[:project_id]) unless params[:project_id].blank?
    end

    def prepare_presenter
      @easy_settings = RedmineExtensions::EasySettingPresenter.new(params[:easy_setting], @project)
    end

    def find_plugin
      @plugin = Redmine::Plugin.find(params[:id])

      return render_404 unless @plugin.settings.is_a?(Hash)

      @easy_settings.plugin = @plugin

    rescue Redmine::PluginNotFound
      render_404
    end
end
