module RedmineExtensions
  class BasePresenter < SimpleDelegator
    attr_reader :model

    def initialize(model, view, options={})
      @model, @view, @options = model, view, options
      super(@model)
    end

    #TODO: little nasty hack
    def class
      @model.class
    end

    def h
      @view
    end

  end
end
