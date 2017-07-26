module EasySettings
  ##
  # EasySettings::KeyDSL
  #
  # For a comfortable way how to set new key via DSL
  #
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

    def skip_blank_params
      @options[:skip_blank_params] = true
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
end
