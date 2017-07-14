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
        key_dsl = KeyDSL.new
        key_dsl.instance_eval(&block)
        options = options.merge(key_dsl.options)
      end

      EasySetting.mapper_clear_caches
      @all_keys[name] = Key.init(name, options)
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

    class KeyDSL

      attr_reader :options

      def initialize
        @options = {}
      end

      def type(new_type)
        @options[:type] = new_type
      end

      def default(new_default)
        @options[:default] = new_default
      end

      def disabled_from_params
        @options[:disabled_from_params] = true
      end

      def from_params(func=nil, &block)
        @options[:from_params] = func || block
      end

      def validate(func=nil, &block)
        @options[:validate] = func || block
      end

      def after_save(func=nil, &block)
        @options[:after_save] = func || block
      end

    end

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
end
