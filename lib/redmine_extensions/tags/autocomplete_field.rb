require 'action_view/helpers/tags/placeholderable'

module RedmineExtensions
  module Tags
    class AutocompleteField < ActionView::Helpers::Tags::Base
      include ActionView::Helpers::Tags::Placeholderable

      def initialize(object_name, method_name, template_object, choices, options, html_options)
        @choices = block_given? ? template_object.capture { yield || "" } : choices
        @choices = @choices.to_a if @choices.is_a?(Range)

        options[:multiple] = true unless options.key?(:multiple)

        @html_options = html_options

        super(object_name, method_name, template_object, html_options.merge(options))
      end

      def render
        options = @options.stringify_keys
        options["value"] = options.fetch("value") { value_before_type_cast(object) }
        add_default_name_and_id(options)
        @template_object.autocomplete_field_tag(options.delete('name'), @choices, options.delete('value'), options.symbolize_keys)
      end

    end
  end
end
