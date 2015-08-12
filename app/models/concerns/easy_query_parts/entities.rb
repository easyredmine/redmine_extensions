module EasyQueryParts
  module Entities
    extend ActiveSupport::Concern

    # Returns the entities count
    def entity_count(options={})
      options[:joins] = Array(options[:joins]) + self.joins_for_order_statement((options[:group] || '').to_s, :array)
      scope = merge_scope(self.new_entity_scope, options)
      scope.count
    end

    # Returns the issues
    # Valid options are :order, :offset, :limit, :include, :conditions
    def entities(options={})
      scope = create_entity_scope(options)

      if has_custom_field_column?
        scope = scope.preload(:custom_values)
      end

      scope.to_a

    rescue ::ActiveRecord::StatementInvalid => e
      raise StatementInvalid.new(e.message)
    end

    def new_entity_scope
      scope = self.entity_scope.where(self.statement)

      includes = Array.wrap(self.default_find_include).dup
      preload = Array.wrap(self.default_find_preload).dup
      joins = Array.wrap(self.default_find_joins).dup
      self.filters.keys.each do |filter|
        f = available_filters[filter]
        if f && f[:includes]
          includes.concat(Array.wrap(f[:includes]))
        end
        if f && f[:joins]
          joins.concat(Array.wrap(f[:joins]))
        end
      end
      self.columns.each do |c|
        includes.concat(Array.wrap(c.includes)) if c.includes
        joins.concat(Array.wrap(c.joins)) if c.joins
        preload.concat(Array.wrap(c.preload)) if c.preload
      end
      if self.grouped? && (c = self.group_by_column) && !self.columns.include?(c)
        includes.concat(Array.wrap(c.includes)) if c.includes
        joins.concat(Array.wrap(c.joins)) if c.joins
        preload.concat(Array.wrap(c.preload)) if c.preload
      end

      possible_columns = Array.new
      possible_columns << self.group_by.to_sym if self.group_by?
      possible_columns.concat(self.sort_criteria.collect { |s| s.first.to_sym })

      available_includes = self.available_columns.inject({}) { |memo, var| memo[var.name] = Array.wrap(var.includes); memo }

      possible_columns.each do |c|
        if s = available_includes[c.to_sym]
          includes.concat(s) if s
        end
      end

      includes.uniq!; joins.uniq!; preload.uniq!
      scope.includes(includes).references(includes).joins(joins).preload(preload)
    end

    def create_entity_scope(options={})
      if options[:only_group_order]
        order_option = self.group_by_sort_order
      else
        order_option = [self.group_by_sort_order, (options[:order] || self.sort_criteria_to_sql_order)].reject { |s| s.blank? }.join(', ')
      end
      order_option = nil if order_option.blank?
      scope_options = options.merge({:order => order_option, :joins => Array(options[:joins]) + joins_for_order_statement(order_option, :array)})

      # PostgreSQL hack
      # remove order wher it is not needed
      #
      # FIXME: NEED KEEP order_option for joins_for_order_statement (for cf)
      #
      scope_options.delete(:order) if options[:skip_order]

      scope = merge_scope(self.new_entity_scope, scope_options)

      scope
    end


    def merge_scope(scope, options={})
      options ||= {}

      scope = scope.where(options[:where]) if options[:where]
      scope = scope.where(options[:conditions]) if options[:conditions]
      scope = scope.includes(options[:includes]) if options[:includes]
      scope = scope.preload(options[:preload]) if options[:preload]
      scope = scope.joins(options[:joins]) if options[:joins]
      scope = scope.order(options[:order]) if options[:order]
      scope = scope.group(options[:group]) if options[:group]
      scope = scope.limit(options[:limit]) if options[:limit]
      scope = scope.offset(options[:offset]) if options[:offset]
      scope
    end

  end
end
