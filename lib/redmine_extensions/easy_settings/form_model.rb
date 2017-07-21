module EasySettings
  ##
  # EasySettings::FormModel
  #
  # Fake models/proxy for easy seettings. Usable in rails form.
  #
  #   settings = EasySettings::FormModel.new(prefix: 'easy_gantt')
  #   settings.show_holidays == EasySetting.value(:easy_gantt_show_holidays)
  #
  class FormModel

    def initialize(prefix: nil, project: nil)
      @prefix = "#{prefix}_" if prefix.present?
      @project_id = project.is_a?(Project) ? project.id : project
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

    # Called for missing :id parameter
    #
    # def to_param
    # end

    def method_missing(name, *args)
      EasySetting.value("#{@prefix}#{name}", @project_id)
    end

  end
end
