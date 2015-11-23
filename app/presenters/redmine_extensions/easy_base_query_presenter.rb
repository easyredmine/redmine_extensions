module RedmineExtensions
  class EasyBaseQueryPresenter < BasePresenter

    def entities
      view.instance_variable_get(:@entities)
    end

    def outputs
      @outputs ||= RedmineExtensions::QueryOutput::Outputs.new(self)
    end

  end
end
