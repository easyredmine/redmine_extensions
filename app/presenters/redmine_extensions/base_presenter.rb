module RedmineExtensions
  class BasePresenter < SimpleDelegator
    attr_reader :model, :options

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

    #TODO: little nasty hack
    def class
      @model && @model.class || super
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
