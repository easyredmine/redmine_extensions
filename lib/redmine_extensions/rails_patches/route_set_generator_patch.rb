module RedmineExtensions
  module RailsPatches
    module RouteSetGeneratorPatch

      def self.included(base)

        base.class_eval do
          def use_relative_controller_with_redmine_extensions!
            return if current_controller && current_controller.start_with?('redmine_extensions')
            use_relative_controller_without_redmine_extensions!
          end

          alias_method_chain :use_relative_controller!, :redmine_extensions
        end

      end

    end
  end
end
