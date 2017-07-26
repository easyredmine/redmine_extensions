module EasySettings
  class Mapper

    def initialize
      @all_keys = {}
    end

    # Be careful for double definition of the same key
    # Last definition wins
    def key(name, **options, &block)
      name = name.to_s

      if block_given?
        key_dsl = EasySettings::KeyDSL.new
        key_dsl.instance_eval(&block)
        options = options.merge(key_dsl.options)
      end

      EasySetting.mapper_clear_caches
      @all_keys[name] = EasySettings::Key.init(name, options)
    end
    alias_method :add_key, :key

    def keys(*names, **options, &block)
      names.each do |name|
        key(name, options, &block)
      end
    end
    alias_method :add_keys, :keys

    # Shortcust due to frequent usage
    def boolean_keys(*names)
      names.each do |name|
        key(name, type: 'boolean')
      end
    end

    def default_values
      values = {}
      @all_keys.each do |name, key|
        values[name] = key.default
      end
      values
    end

    def validate(easy_setting)
      if @all_keys.has_key?(easy_setting.name)
        @all_keys[easy_setting.name].validate(easy_setting)
      else
        true
      end
    end

    def after_save(easy_setting)
      if @all_keys.has_key?(easy_setting.name)
        @all_keys[easy_setting.name].after_save(easy_setting)
      else
        true
      end
    end

    def from_params(easy_setting, value)
      if @all_keys.has_key?(easy_setting.name)
        @all_keys[easy_setting.name].from_params(easy_setting, value)
      else
        value
      end
    end

    def disabled_from_params?(easy_setting)
      if @all_keys.has_key?(easy_setting.name)
        @all_keys[easy_setting.name].disabled_from_params?
      else
        false
      end
    end

    def skip_blank_params?(easy_setting)
      if @all_keys.has_key?(easy_setting.name)
        @all_keys[easy_setting.name].skip_blank_params?
      else
        false
      end
    end

  end
end
