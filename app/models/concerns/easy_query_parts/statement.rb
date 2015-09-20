module EasyQueryParts
  module Statement
    extend ActiveSupport::Concern

    included do
      attr_accessor :additional_statement
    end

    def add_statement_sql_before_filters
      nil
    end

    def default_additional_statement
      nil
    end

    def statement_skip_fields
      []
    end

    def statement
      # filters clauses
      filters_clauses = []

      sql = self.add_statement_sql_before_filters
      filters_clauses << sql if sql.present?

      self.filters.each_key do |field|
        next if self.statement_skip_fields.include?(field)
        v = self.values_for(field)
        operator = self.operator_for(field)
        next if !EasyQueryFilter.hidden_values_by_operator.include?(operator) && v.blank?

        v = v.nil? ? '' : v.dup

        if self.columns_with_me.include?(field)
          if v.is_a?(Array) && v.delete('me')
            if User.current.logged?
              v.push(User.current.id.to_s)
              v.concat(User.current.group_ids.map(&:to_s)) if field == 'assigned_to_id'
            else
              v.push('0')
            end
          elsif v == 'me'
            v = User.current.id.to_s
          end
        end

        if field == 'project_id'
          if !v.blank? && v.delete('mine')
            v.concat(User.current.memberships.puck(:project_id).collect(&:to_s))
          end
        end

        custom_sql = self.get_custom_sql_for_field(field, operator, v)
        if custom_sql.present?
          filters_clauses << custom_sql
        else
          filter = available_filters[field]
          filters_clauses << filter.sql(field, operator, v) if filter
        end

      end if self.filters

      if (c = group_by_column) && c.is_a?(EasyQueryCustomFieldColumn)
        # Excludes results for which the grouped custom field is not visible
        filters_clauses << c.custom_field.visibility_by_project_condition
      end

      filters_clauses << self.default_additional_statement if self.default_additional_statement.present?
      filters_clauses << self.additional_statement if self.additional_statement.present?
      filters_clauses.reject!(&:blank?)
      filters_clauses.any? ? filters_clauses.join(' AND ') : nil
    end

  end
end
