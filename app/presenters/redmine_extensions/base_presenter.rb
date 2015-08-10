module RedmineExtensions
  class BasePresenter < SimpleDelegator
    attr_reader :model

    def initialize(model, view, options={})
      @model, @view, @options = model, view, options
      super(@model)
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
