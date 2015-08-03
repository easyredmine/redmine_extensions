module RedmineExtensions
  module QueryOutputs
    class TableOutput < RedmineExtensions::QueryOutput

      def render_data
        h.render 'easy_queries/easy_query_table', variables
      end

    end
  end
end
