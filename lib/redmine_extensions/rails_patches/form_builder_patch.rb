module RedmineExtensions
  module RailsPatches
    module FormBuilderPatch

      # See documentation for autocomplete_field in helper
      def autocomplete_field(method, choices, options={}, html_options={})
        @template.autocomplete_field(@object_name, method, choices, objectify_options(options), html_options)
      end

    end
  end
end
