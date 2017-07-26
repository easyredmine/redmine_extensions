module EasySettings
  ##
  # EasySettings::Key
  #
  # Definition of easy setting key
  #
  class Key

    attr_reader :name, :options

    def self.init(name, **options)
      key_class =
        case options[:type].to_s
        when 'boolean', 'bool'
          BooleanKey
        when 'integer', 'int'
          IntegerKey
        when 'float'
          FloatKey
        else
          Key
        end

      key_class.new(name, options)
    end

    def initialize(name, **options)
      @name = name
      @options = options
    end

    def default
      @options[:default]
    end

    def validate(easy_setting)
      if options[:validate].is_a?(Proc)
        easy_setting.instance_eval(&options[:validate])
      end
    end

    def after_save(easy_setting)
      if options[:after_save].is_a?(Proc)
        easy_setting.instance_eval(&options[:after_save])
      end
    end

    def from_params(easy_setting, value)
      if options[:from_params].is_a?(Proc)
        easy_setting.instance_exec(value, &options[:from_params])
      else
        value
      end
    end

    def disabled_from_params?
      !!options[:disabled_from_params]
    end

    def skip_blank_params?
      !!options[:skip_blank_params]
    end

  end

  class BooleanKey < Key

    def from_params(easy_setting, value)
      value.to_s.to_boolean
    end

    def validate(easy_setting)
      easy_setting.instance_eval do
        if ![nil, true, false].include?(value)
          errors.add(:base, "#{name} must be boolean")
        end
      end
    end

  end

  class IntegerKey < Key

    def from_params(easy_setting, value)
      value.try(:to_i)
    end

    def validate(easy_setting)
      easy_setting.instance_eval do
        if !value.nil? && !value.is_a?(Integer)
          errors.add(:base, "#{name} must be inetger")
        end
      end
    end

  end

  class FloatKey < Key

    def from_params(easy_setting, value)
      value.try(:to_f)
    end

    def validate(easy_setting)
      easy_setting.instance_eval do
        if !value.nil? && !value.is_a?(Float)
          errors.add(:base, "#{name} must be float")
        end
      end
    end

  end
end
