module EasyQueryParts
  module Groupable

    def default_group_by
      nil
    end

    # Returns true if the query is a grouped query
    def grouped?
      !self.group_by_column.nil?
    end

    def group_by_column
      self.groupable_columns.detect { |c| c.groupable && c.name.to_s == self.group_by }
    end

    def group_by_statement
      grouping_col = self.group_by_column
      if grouping_col.polymorphic?
        self.group_by_column.polymorphic[:name].to_s + '_id'
      else
        res = grouping_col && (self.group_by_column.sumable_sql || self.group_by_column.groupable)
        if res.is_a?(String) && res.match(/^\w+$/)
          association = entity.reflect_on_association(res.to_sym)
          associated = association && association.macro == :belongs_to # only count belongs_to associations
          res = "#{self.entity.quoted_table_name}.#{associated ? association.foreign_key : res}"
        end
        res
      end
    end

    # Returns group count
    def groups_count(options={})
      return 0 unless self.grouped?
      options = options.dup # only_group_order is propagated so result from query.prepare_result is not sorted
      options[:only_group_order] = true #postgres complaining and wee dont need it
      options[:joins] = Array(options[:joins]) + self.group_by_column.additional_joins(entity, :array)
      group_by = self.group_by_statement
      group_by += self.additional_group_by(:skip_order => true)
      scope = create_entity_scope(options.merge({:skip_order => true})).group(group_by)
      scope.count.keys.count
    end


    # Returns the SQL sort order that should be prepended for grouping
    def group_by_sort_order
      if self.grouped? && (column = self.group_by_column)
        order = self.sort_criteria_order_for(column.name) || column.default_order
        column.sortable.is_a?(Array) ?
          column.sortable.collect { |s| "#{s} #{order}" }.join(',') :
          "#{column.sortable} #{order}"
      end
    end

  end
end
