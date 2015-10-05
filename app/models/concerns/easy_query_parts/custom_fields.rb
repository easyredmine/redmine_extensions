begin
  require_dependency Rails.root.join('plugins', 'easyproject', 'easy_plugins', 'easy_extensions', 'app', 'models', 'easy_entity_custom_attribute')
rescue LoadError
  class EasyQueryCustomFieldColumn < EasyQueryColumn
    attr_reader :custom_field

    def initialize(custom_field, options={})
      @custom_field = custom_field
      options[:groupable] = custom_field.group_statement || false
      super("cf_#{custom_field.id}".to_sym, options)
      @inline = true
    end

    def caption(with_suffixes=false)
      custom_field.translated_name
    end

    def value_object(entity, options={})
      return nil if entity.nil?

      entity = entity.send(assoc) if assoc

      return nil if entity.nil?

      if (entity.respond_to?(:project) && @custom_field.visible_by?(entity.project, User.current)) || !entity.respond_to?(:project)
        cv = entity.custom_values.enabled.select {|v| v.custom_field_id == @custom_field.id}
        cv.size > 1 ? cv.sort {|a,b| a.value.to_s <=> b.value.to_s} : cv.first
      else
        nil
      end
    end

    def value(entity, options={})
      raw = value_object(entity, options)
      if raw.is_a?(Array)
        raw.map {|r| @custom_field.cast_value(r.value)}
      elsif raw
        @custom_field.cast_value(raw.value)
      else
        nil
      end
    end

    def custom_value_of(entity)
      entity = entity.send(assoc) if assoc
      cv = entity.custom_value_for(@custom_field)
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

  Rails.logger.warn 'EasyRedmine is not installed, please visit a www.easyredmine.com for feature preview and consider installation.'
end

module EasyQueryParts
  module CustomFields

    def has_custom_field_column?
      columns.any? { |column| column.is_a? EasyQueryCustomFieldColumn }
    end

  end
end
