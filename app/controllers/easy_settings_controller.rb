#
# For now edit and update actions are for a plugin settings
#
class EasySettingsController < ApplicationController

  before_filter :find_optional_project
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
    @settings = Setting.send("plugin_#{@plugin.id}")
    @easy_settings = EasySettings::PluginModel.new(@plugin, project: @project)
  end

  def update
    if params[:settings]
      Setting.send("plugin_#{@plugin.id}=", params[:settings])
    end

    if params[:easy_setting]
      @easy_settings = EasySettings::ParamsWrapper.from_params(params[:easy_setting], project: @project, prefix: @plugin.id)

      if @easy_settings.save
        # All good
      else
        render :edit
        return
      end
    end

    flash[:notice] = l(:notice_successful_update)
    redirect_back_or_default edit_easy_setting_path(@plugin.id)
  end

  private

    def find_optional_project
      @project = Project.find_by(id: params[:project_id]) if params[:project_id].present?
    end

    def find_plugin
      @plugin = Redmine::Plugin.find(params[:id])
      return render_404 unless @plugin.settings.is_a?(Hash)
    rescue Redmine::PluginNotFound
      render_404
    end

end
