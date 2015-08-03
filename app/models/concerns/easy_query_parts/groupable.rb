module EasyQueryParts
  module Groupable

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

  end
end
