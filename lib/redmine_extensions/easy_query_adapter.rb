require 'query'

module RedmineExtensions
  module QueryColumnAdapter
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        attr_accessor :includes
        attr_accessor :joins
        attr_accessor :preload
      end
    end

    module InstanceMethods
    end

    module ClassMethods
    end
  end

  module QueryAdapter

    attr_writer :outputs

    def outputs
      @outputs ||= ['list']
    end

    def output=(output_t)
      self.outputs = Array.wrap(output_t)
    end

    def default_find_include
      [].freeze
    end

    def default_find_preload
      [].freeze
    end

    def default_find_joins
      [].freeze
    end

    def default_list_columns
      [].freeze
    end

    def formatter
      @formatter
    end

    def init_formatter(object)
      return @formatter if @formatter

      if entity
        begin
          formatter_klass = "#{entity}Formatter".constantize
        rescue NameError
        end
      end

      formatter_klass ||= EasyEntityFormatter
      @formatter = formatter_klass.new(object)
    end

    def entity
      self.class.queried_class
    end

    def entity_scope
      if !@entity_scope.nil?
        @entity_scope
      elsif entity.respond_to?(:visible)
        entity.visible
      else
        entity
      end
    end

    def set_entity_scope(entity, reference_collection = nil)
      return nil if entity.nil? || reference_collection.nil?

      @entity_scope = entity.send(reference_collection.to_sym)

      self.filters = {}

      @entity_scope
    end

    def create_entity_scope(options={})
      scope = entity_scope.where(statement)

      includes = default_find_include.dup
      includes.concat(Array.wrap(options[:includes]))

      preload = default_find_preload.dup
      preload.concat(Array.wrap(options[:preload]))

      joins = default_find_joins.dup
      joins.concat(Array.wrap(options[:joins]))

      filters.keys.each do |filter|
        f = available_filters[filter]
        next if f.blank?

        includes.concat(Array.wrap(f[:includes])) if f[:includes]
        joins.concat(Array.wrap(f[:joins])) if f[:joins]
      end if filters

      columns.each do |c|
        includes.concat(Array.wrap(c.includes)) if c.includes
        joins.concat(Array.wrap(c.joins)) if c.joins
        preload.concat(Array.wrap(c.preload)) if c.preload
      end

      if project
        includes << :project
      end

      includes.uniq!
      joins.uniq!
      preload.uniq!

      scope.includes(includes).references(includes).joins(joins).preload(preload)
    end

    def entities(options={})
      create_entity_scope(options).order(options[:order]).to_a
    end

    def add_available_column(name, options={})
      @available_columns ||= []

      @available_columns << QueryColumn.new(name.to_sym, options)
    end

    def to_partial_path
      'easy_queries/index'
    end

    def default_columns_names
      default_list_columns
    end

    def queried_table_name
      entity.table_name
    end

  end

  module QueryAdapterDefaults

    def initialize(attributes=nil, *args)
      super
      self.filters ||= {}
    end

  end

end

class EasyQueryAdapter < Query
end

if Redmine::Plugin.installed?(:easy_extensions)
  # EasyQuery exist
else
  QueryColumn.send(:include, RedmineExtensions::QueryColumnAdapter)
  RedmineExtensions::PatchManager.register_model_patch('Query', 'RedmineExtensions::QueryAdapter')
  EasyQuery = EasyQueryAdapter
  EasyQuery.prepend(RedmineExtensions::QueryAdapterDefaults)
end
