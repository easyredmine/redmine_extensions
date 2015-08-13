module EasyQueryParts
  module Summable


    # Returns the sum of _column_ or column
    # TODO: znovu, lepe!!!
    def entity_sum(column, options={})
      c = column
      column = columns.detect { |c| c.name.to_sym == column } if column.is_a?(Symbol)
      unless column.is_a?(EasyEntityAttribute)
        scope = merge_scope(self.new_entity_scope, options)
        return scope.sum(column || c)
      end

      if column.sumable_sql == false && options[:entities]
        query_entities = options[:entities].is_a?(Array) ? options[:entities] : entities
        return summarize_column(column, query_entities)
      end
      if column.sumable_sql == false && column.visible? && options[:group]
        unless @grouped_scope
          additional_joins = column.additional_joins(entity, :array) + joins_for_order_statement(options[:group].to_s, :array)
          options[:joins] = options[:joins].to_a + additional_joins
          @grouped_scope = merge_scope(self.new_entity_scope, options.merge({group: nil}))
        end
        results = {}
        @grouped_scope.to_a.each do |e|
          g = group_by_column.value(e)
          group_id = (g.is_a?(ActiveRecord::Base) ? g.id : g) || ''
          results[group_id] ? results[group_id] += column.value(e) : results[group_id] = column.value(e)
        end
        return results
      end

      additional_joins = column.additional_joins(entity, :array) + joins_for_order_statement(options[:group].to_s, :array)
      options[:joins] = Array(options[:joins]) + additional_joins
      column_name = column.sumable_sql || column.name

      if options[:group].present?
        if options[:group].to_s.match(/^(\w+)\.(\w+)$/)
          group_attr = $2
          group_table = $1
        else
          group_attr = options[:group].to_s
        end
      end

      if column.sumable_options.distinct_columns?

        if options[:group].blank?
          options[:group] = []
          select_group = nil
        else
          association = entity.reflect_on_association(group_attr.to_sym)
          associated = association && association.macro == :belongs_to # only count belongs_to associations
          group_field = associated ? association.foreign_key : "#{group_table + '.' if group_table}" + group_attr
          group_alias = entity_scope.send(:column_alias_for, group_field)
          group_column = entity_column_for group_field
          options[:group] = [(entity.connection.adapter_name == 'FrontBase' ? group_alias : group_field)]
          select_group = group_field.to_s + ' AS ' + group_alias
        end

        options[:group] += column.sumable_options.distinct_columns.collect { |dc| dc =~ /\./ ? dc : "#{entity.quoted_table_name}.#{dc}" }
        scope = merge_scope(self.new_entity_scope, options)
        scope = scope.select('MAX('+column_name.to_s+') AS result')
        scope = scope.select(select_group) if select_group
        sql = scope.send(:construct_relation_for_association_calculations).to_sql

        final_sql = 'SELECT '
        final_sql << group_alias + ', ' if select_group
        final_sql << 'SUM(result) AS result FROM ('
        final_sql << sql
        final_sql << ') AS DT1'
        final_sql << ' GROUP BY ' + group_alias if select_group

        entity_column = column.sumable_options.entity_column self, column.name

        if select_group

          res = entity.connection.select_all(final_sql)
          if association
            key_ids = res.collect { |row| row[group_alias] }
            if key_ids.any?
              key_records = association.klass.base_class.find(key_ids)
            else
              key_records = key_ids
            end
            key_records = Hash[key_records.map { |r| [r.id, r] }]
          end

          result = {}
          res.each do |row|
            key = group_column ? group_column.type_cast_from_database(row[group_alias]) : row[group_alias]
            key = key_records[key] if associated
            result[key] = entity_column ? entity_scope.send(:type_cast_calculated_value, row['result'], entity_column, 'sum') : '' # (row['result'] || '0') pokud maji byt nuly videt
          end
        else
          result = entity_column ? entity_scope.send(:type_cast_calculated_value, entity.connection.select_value(final_sql), entity_column, 'sum') : ''
        end

        result
      else
        scope = merge_scope(self.new_entity_scope, options)
        begin
          scope.sum(column_name)
        rescue ActiveRecord::RecordNotFound
          association = entity.reflect_on_association(group_attr.to_sym)
          associated = association && association.macro == :belongs_to # only count belongs_to associations
          group_field = associated ? association.foreign_key : group_attr

          options[:group] = group_table + '.' + group_field if group_table
          options[:group] ||= group_field

          scope = merge_scope(self.new_entity_scope, options)
          scope.sum(column_name)
        end
      end
    rescue ::ActiveRecord::StatementInvalid => e
      raise StatementInvalid.new(e.message)
    end

  end
end
