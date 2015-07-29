module EasyQueryParts
  module Filters

    def validate_query_filters
      filters.each_key do |field|
        if values_for(field)
          case type_for(field)
            when :integer
              add_filter_error(field, :invalid) if values_for(field).detect { |v| v.present? && !v.match(/^[+-]?\d+$/) }
            when :float
              add_filter_error(field, :invalid) if values_for(field).detect { |v| v.present? && !v.match(/^[+-]?\d+(\.\d*)?$/) }
            when :date, :date_past
              case operator_for(field)
                when '=', '>=', '<=', '><'
                  add_filter_error(field, :invalid) if values_for(field).detect { |v|
                    v.present? && (!v.match(/\A\d{4}-\d{2}-\d{2}(T\d{2}((:)?\d{2}){0,2}(Z|\d{2}:?\d{2})?)?\z/) || parse_date(v).nil?)
                  }
                when '>t-', '<t-', 't-', '>t+', '<t+', 't+', '><t+', '><t-'
                  add_filter_error(field, :invalid) if values_for(field).detect { |v| v.present? && !v.match(/^\d+$/) }
              end
            when :list, :list_optional
              case operator_for(field)
                when '=', '!'
                  values = values_for(field)
                  add_filter_error(field, :invalid) unless values.detect { |v| v.present? }

                  filter = filters_for_select.detect { |name, _| name == field }
                  filter_options = filter.last if filter
                  if filter_options && possible_values = filter_options[:values]

                    # [] - Regular custom fields
                    # [[],[]] - Regular lists & easy lookups
                    possible_values = possible_values.map { |_, val| val.to_s } if possible_values.first.is_a?(Array)

                    add_filter_error(field, :inclusion) if (values - possible_values).any?
                  end
              end
          end
        end
      end if filters
    end

    def add_filter_error(field, message)
      m = label_for(field) + " " + l(message, :scope => 'activerecord.errors.messages')
      errors.add(:base, m)
    end

  end
end
