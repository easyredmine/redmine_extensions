module RedmineExtensions
  module ApplicationControllerPatch

    def self.included(base)
      base.extend ClassMethods
      base.include InstanceMethods

      base.class_eval do
        helper_method :easy_extensions?
      end
    end

    module InstanceMethods

      def index_for_easy_query(query_klass, *)
        @query = query_klass.new(name: '_')
        @query.project = @project
        @query.build_from_params(params)

        sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
        sort_update(@query.sortable_columns)

        @entities = @query.entities
      end

      def easy_extensions?
        self.class.easy_extensions?
      end

      private

      def save_easy_settings(project = nil)
        if params[:easy_setting]
          wrapper = EasySettings::ParamsWrapper.from_params(params.require(:easy_setting).permit!, project: project)
          wrapper.save
          wrapper
        end
      end

    end

    module ClassMethods

      def easy_extensions?
        Redmine::Plugin.installed?(:easy_extensions)
      end

      def include_query_helpers
        if easy_extensions?
          helper :easy_query
          include EasyQueryHelper
        else
          helper :queries
          include QueriesHelper
        end

        helper :sort
        include SortHelper
      end

    end

  end
end
RedmineExtensions::PatchManager.register_controller_patch 'ApplicationController', 'RedmineExtensions::ApplicationControllerPatch'
