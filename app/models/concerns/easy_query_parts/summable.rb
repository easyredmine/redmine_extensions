module EasyQueryParts
  module Summable


    # Returns the sum of _column_ or column
    # TODO: znovu, lepe!!!
    def entity_sum(column, options={})
      c = column
      column = columns.detect { |c| c.name.to_sym == column } if column.is_a?(Symbol)
      unless column.is_a?(EasyQueryColumn)
        scope = merge_scope(self.new_entity_scope, options)
        return scope.sum(column || c)
      end

      column.sum(self, options)
    end

  end
end
