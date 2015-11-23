module RedmineExtensions
  class EasyBaseQueryPresenter < BasePresenter

    def entities
      view.instance_variable_get(:@entities)
    end

    def outputs
      @outputs ||= RedmineExtensions::QueryOutput::Outputs.new(self)
    end

    # --- formating ----

    def format_value(column, entity)
      column.value(entity).to_s
    end


    # --- helpers -----

    def ending_buttons?
      false
    end

  end
end
