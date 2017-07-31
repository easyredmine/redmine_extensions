module EasySettings
  class ParamsWrapper

    attr_reader :errors

    def self.from_params(raw_params, project: nil, prefix: nil)
      if !raw_params.is_a?(Hash) && !raw_params.is_a?(ActionController::Parameters)
        raw_params = {}
      end
      new(raw_params, project, prefix)
    end

    def initialize(raw_params, project, prefix)
      @raw_params = raw_params
      @project_id = project.is_a?(Project) ? project.id : project
      @prefix = "#{prefix}_" if prefix.present?
      @errors = []

      prepare_params
      prepare_easy_settings
    end

    def valid?
      validate
      @errors.empty?
    end

    def save
      @errors.clear

      @easy_settings.each do |setting|
        # TO CONSIDER: Should this line exist?
        #              This skip callbacks after saving
        #              setting but is it desirable?
        next if !setting.changed?

        if setting.save
          # All good
        else
          @errors << [setting, setting.errors]
        end
      end

      @errors.empty?
    end

    private

      def prepare_params
        @params = {}
        @raw_params.each do |name, value|
          @params["#{@prefix}#{name}"] = value
        end
      end

      def prepare_easy_settings
        saved_settings = EasySetting.where(name: @params.keys, project_id: @project_id).map{|e| [e.name, e] }.to_h

        @easy_settings = []
        @params.each do |name, value|
          setting = saved_settings[name]
          setting ||= EasySetting.new(name: name, project_id: @project_id)
          next if setting.disabled_from_params?
          next if value.blank? && setting.skip_blank_params?

          setting.from_params(value)
          @easy_settings << setting
        end
      end

      def validate
        @errors.clear
        @easy_settings.each do |setting|
          if !setting.valid?
            @errors << [setting, setting.errors]
          end
        end
      end

  end
end
