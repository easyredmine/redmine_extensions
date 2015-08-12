class EasyQueryCustomFieldColumn < EasyQueryColumn
end

module EasyQueryParts
  module CustomFields

    def has_custom_field_column?
      columns.any? { |column| column.is_a? EasyQueryCustomFieldColumn }
    end

  end
end
