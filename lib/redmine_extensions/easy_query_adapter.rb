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
end

class EasyQueryAdapter < Query

  after_initialize :after_initialize

  def after_initialize
    self.filters ||= {}
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

  def outputs
    ['table']
  end

  def entity_scope
    if @entity_scope.present?
      @entity_scope
    elsif entity.respond_to?(:visible)
      entity.visible
    else
      entity
    end
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
    create_entity_scope(options).order(options[:order])
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

if Redmine::Plugin.installed?(:easy_extensions)
  # EasyQuery exist
else
  QueryColumn.send(:include, RedmineExtensions::QueryColumnAdapter)
  EasyQuery = EasyQueryAdapter
end
