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
      @formatter ||= formatter_klass.new(view)
    end

    def format_value(column, entity)
      formatter.format(column, entity)
    end


    # --- helpers -----

    def ending_buttons?
      false
    end


    private
      def formatter_klass
        formatter_klass = "#{self.model.entity}Formatter".constantize
      rescue
        formatter_klass = RedmineExtensions::EasyEntityFormatter
      end

  end
end
