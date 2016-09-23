module RedmineExtensions
  module QueryOutputs
    class TilesOutput < RedmineExtensions::QueryOutput

      def self.key
        'tiles'
      end

      def entity
        options[:entity]
      end

      def render_entity_tile(referenced_entity)
        referenced_entity.to_s
      end

    end
  end
end
