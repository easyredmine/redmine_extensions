module RedmineExtensions
  module QueryOutputs
    class TableOutput < RedmineExtensions::QueryOutput

      def render_data
        h.render partial: 'easy_queries/easy_query_table', locals: variables
      end

    end
  end
end
