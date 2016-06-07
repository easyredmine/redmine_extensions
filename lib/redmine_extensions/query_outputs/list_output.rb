module RedmineExtensions
  module QueryOutputs
    class ListOutput < RedmineExtensions::QueryOutput

      def self.key
        'list'
      end

      def render_period_header
      end

    end
  end
end
