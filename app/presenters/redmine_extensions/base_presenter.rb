module RedmineExtensions
  class BasePresenter < SimpleDelegator
    attr_reader :model, :options

    def self.registered_presenters
      @registered_presenters ||= {}
    end

    def self.register(klass_name, *for_classes)
      for_classes = [klass_name.sub(/Presenter$/, '')] unless for_classes.any?
      for_classes.each do |name|
        registered_presenters[name] = klass_name
      end
    end

    def self.presenter_for(model)
      klasses = model.hiearchy.map do |klass|
        (registered_presenters[klass] || "#{klass}Presenter").constantize rescue nil
      end.compact
      raise NameError, 'presenter for ' + model.class.name + ' is not registered' unless klasses.any?
      klasses.first
    end

    def self.present(model, view, options={})
      presenter_for(model).new(model, view, options)
    end

    def initialize(model, view, options={})
      @model, @view, @options = model, view, options
      super(@model)
    end

    def update_options(options={})
      @view = options.delete(:view_context) if options.key?(:view_context)
      @options.merge!(options)
      self
    end

    def to_model
      @model || self
    end

    def h
      @view
    end

    protected
      def model=(model)
        @model = model
        __setobj__(model)
      end

  end
end
