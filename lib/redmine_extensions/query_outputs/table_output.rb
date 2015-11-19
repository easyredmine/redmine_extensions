module RedmineExtensions
  module QueryOutputs
    class TableOutput < RedmineExtensions::QueryOutput

      def self.key
        'table'
      end

      def render_period_header
      end

    end
  end
end
