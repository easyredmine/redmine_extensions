module RedmineExtensions
  class EasyQueryAdapterPresenter < BasePresenter

    def entities
      view.instance_variable_get(:@entities)
    end

    def outputs
      @outputs ||= RedmineExtensions::QueryOutput::Outputs.new(self)
    end

    # --- formating ----

    def formatter
      @formatter ||= ("#{self.model.entity}Formatter".constantize rescue RedmineExtensions::EasyEntityFormatters::EasyEntityFormatter).new(view)
    end

    def format_value(column, entity)
      formatter.format(column, entity)
    end


    # --- helpers -----

    def ending_buttons?
      false
    end

  end
end
