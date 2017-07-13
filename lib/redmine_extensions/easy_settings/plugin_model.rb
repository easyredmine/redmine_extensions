module EasySettings
  ##
  # EasySettings::PluginModel
  #
  # Fake models/proxy for easy seettings. Usable in rails form.
  #
  #   plugin = Redmine::Plugin.find('easy_gantt')
  #   settings = EasySettings::PluginModel.new(plugin)
  #   settings.show_holidays == EasySetting.value(:easy_gantt_show_holidays)
  #
  class PluginModel

    def initialize(plugin, project: nil)
      @plugin = plugin
      @project = project
      @project = project.id if project.is_a?(Project)
    end

    def model_name
      EasySetting.model_name
    end

    def persisted?
      true
    end

    def to_model
      self
    end

    def to_param
      @plugin.id
    end

    def method_missing(name, *args)
      EasySetting.value("#{@plugin.id}_#{name}", @project)
    end

  end
end
