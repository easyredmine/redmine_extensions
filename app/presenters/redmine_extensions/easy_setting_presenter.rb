module RedmineExtensions
  class EasySettingPresenter < BasePresenter

    attr_accessor :project_id, :plugin

    def self.boolean_keys
      @boolean_keys ||= BooleanKeysAlsoToMapperKey.new
    end

    def initialize(settings_params={}, project = nil)
      ActiveSupport::Deprecation.warn('RedmineExtensions::EasySettingPresenter is deprecated in favor of EasySettings::ParamsWrapper.')

      @settings = settings_params || {}
      @settings = @settings.dup.symbolize_keys
      self.project = project
      super(EasySetting.new, nil)
    end

    def project=(project_or_project_id)
      if project_or_project_id.is_a?(Project)
        @project_id = project_or_project_id.id
      elsif !project_or_project_id.nil?
        @project_id = project_or_project_id.to_i
      else
        @project_id = nil
      end
      @easy_settings = nil
    end

    def plugin=(plugin)
      @plugin = plugin
      self.model = plugin
    end

    def unsaved_settings
      @unsaved_settings ||= []
    end

    def easy_settings
      @easy_settings ||= @settings.collect do |name, value|
        # remove blank values in array settings
        value.delete_if{|v| v.blank? } if value.is_a?(Array)
        name = prefix+name.to_s

        set = EasySetting.where(name: name.to_s, project_id: project_id).first || EasySetting.new(name: name.to_s, project_id: project_id)

        set.value = format_value(name, value)

        set
      end
    end

    def persisted?
      !!@plugin
    end

    def id
      @plugin && @plugin.id
    end

    def prefix
      @plugin && (@plugin.id.to_s + '_') || ''
    end

    # TODO: form rendering methods. Maybe push them to the parent?
    def to_model
      self
    end
    def model_name
      EasySetting.model_name
    end
    def param_key
      EasySetting.param_key
    end
    def to_key
      @plugin && [@plugin.id]
    end

    # TODO - more dynamic solution?
    def boolean_keys
      from_easy_setting = EasySetting.boolean_keys
      ActiveSupport::Deprecation.warn("EasySetting.boolean_keys has been deprecated, use EasySettingPresenter#boolean_keys instead") if from_easy_setting.any?
      from_easy_setting.concat(self.class.boolean_keys)
    end

    def save
      unsaved_settings.clear
      easy_settings.each do |setting|
        setting.save
        unsaved_settings << setting unless setting.persisted?
      end
      unsaved_settings.empty?
    end

    def format_value(name, value)
      case name.to_sym
      when *boolean_keys
        value.to_boolean
      when :attachment_description
        esa = EasySetting.where(:name => 'attachment_description_required', :project_id => nil).first
        case value
        when 'required'
          esa.update_attribute(:value, true)
          true
        when '1'
          esa.update_attribute(:value, false)
          true
        else
          esa.update_attribute(:value, false)
          false
        end
      when :agile_board_statuses
        value[:progress] = value.delete('progress') if value["progress"]
        value[:done] = value.delete('done') if value["done"]
        value
      else
        value
      end
    end

    def method_missing(meth, *attrs)
      if @plugin && @plugin.settings[:easy_settings] && @plugin.settings[:easy_settings].keys.include?(meth.to_sym)
        EasySetting.value(prefix+meth.to_s, project_id)
      else
        super
      end
    end

    # To keep backward compatibility with old presenter
    class BooleanKeysAlsoToMapperKey < Array

      def <<(key)
        EasySetting.map.key(key, type: 'boolean')
        super
      end

      def concat(keys)
        EasySetting.map.keys(*keys, type: 'boolean')
        super
      end

    end

  end
end
