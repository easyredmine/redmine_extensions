module RedmineExtensions
  module QueryOutputs
    class TileOutput < RedmineExtensions::QueryOutput

      def self.key
        'tile'
      end

      def entity
        options[:entity]
      end

      def render_entity_card(referenced_entity)
        referenced_entity.to_s
      end

      def render_data
        h.content_tag(:div, class: 'easy-entity-cards-container') do
          h.content_tag(:div, class: 'splitcontent') do
            query.entities.map do |referenced_entity|
              render_entity_card(referenced_entity)
            end.join('').html_safe
          end
        end
      end

      def render_period_header
      end

    end
  end
end
