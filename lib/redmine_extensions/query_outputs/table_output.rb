module RedmineExtensions
  module QueryOutputs
    class TableOutput < RedmineExtensions::QueryOutput

      def render_data
        h.render partial: 'easy_queries/easy_query_table', locals: variables
      end

      def render_period_header
      end

    end
  end
end
