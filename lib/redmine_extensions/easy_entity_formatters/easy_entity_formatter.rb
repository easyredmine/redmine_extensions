module RedmineExtensions
  module EasyEntityFormatters
    class EasyEntityFormatter
      include Rails.application.routes.url_helpers

      def initialize(view_context)
        @view_context = view_context
      end

      def view
        @view_context
      end

      def l(*args)
        view.l(*args)
      end

      def format_object(value)
        view.format_object(value)
      end

      def format(column, entity)
        format_object column.value(entity)
      end

      def format_column(column, entity)
        format_object column.value_object(entity)
      end
    end
  end
end
