class EasyQueryCustomFieldColumn < EasyQueryColumn
  attr_reader :custom_field

  def initialize(custom_field, options={})
    @custom_field = custom_field
    super("cf_#{custom_field.id}".to_sym, options)
  end

  def additional_joins(entity_cls, type=nil)
    super.tap do |result|
      result << assoc if assoc

      join_statement = custom_field.join_for_order_statement
      result << join_statement unless join_statement.blank?
    end
  end

  def sumable_sql
    custom_field.summable_sql
  end

  def sumable_top?
    custom_field.summable?
  end
  def sumable_bottom?
    custom_field.summable?
  end

end

module EasyQueryParts
  module CustomFields

    def has_custom_field_column?
      columns.any? { |column| column.is_a? EasyQueryCustomFieldColumn }
    end

  end
end
