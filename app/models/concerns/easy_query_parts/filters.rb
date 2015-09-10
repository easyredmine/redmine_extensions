class EasyQueryFilter < Hash

  class_attribute :operators
  self.operators = {
    '=' => :label_equals,
    '!' => :label_not_equals,
    'o' => :label_open_issues,
    'c' => :label_closed_issues,
    '!*' => :label_none,
    '*' => :label_any,
    '>=' => :label_greater_or_equal,
    '<=' => :label_less_or_equal,
    '><' => :label_between,
    '<t+' => :label_in_less_than,
    '>t+' => :label_in_more_than,
    '><t+' => :label_in_the_next_days,
    't+' => :label_in,
    't' => :label_today,
    'ld' => :label_yesterday,
    'w' => :label_this_week,
    'lw' => :label_last_week,
    'l2w' => [:label_last_n_weeks, {:count => 2}],
    'm' => :label_this_month,
    'lm' => :label_last_month,
    'y' => :label_this_year,
    '>t-' => :label_less_than_ago,
    '<t-' => :label_more_than_ago,
    '><t-' => :label_in_the_past_days,
    't-' => :label_ago,
    '~' => :label_contains,
    '!~' => :label_not_contains,
    '^~' => :label_starts_with,
    '=p' => :label_any_issues_in_project,
    '=!p' => :label_any_issues_not_in_project,
    '!p' => :label_no_issues_in_project
  }

  class_attribute :operators_by_filter_type
  self.operators_by_filter_type = {
    :boolean => ['='],
    :list => ['=', '!'],
    :list_autocomplete => ['=', '!'],
    :list_status => ['o', '=', '!', 'c', '*'],
    :list_optional => ['=', '!', '!*', '*'],
    :list_subprojects => ['*', '!*', '='],
    :date => ['=', '>=', '<=', '><', '<t+', '>t+', '><t+', 't+', 't', 'ld', 'w', 'lw', 'l2w', 'm', 'lm', 'y', '>t-', '<t-', '><t-', 't-', '!*', '*'],
    :date_past => ['=', '>=', '<=', '><', '>t-', '<t-', '><t-', 't-', 't', 'ld', 'w', 'lw', 'l2w', 'm', 'lm', 'y', '!*', '*'],
    :date_period => ['date_period_1', 'date_period_2'],
    :string => ['=', '~', '!', '!~', '^~', '!*', '*'],
    :text => ['~', '!~', '^~', '!*', '*'],
    :integer => ['=', '>=', '<=', '><', '!*', '*'],
    :float => ['=', '>=', '<=', '><', '!*', '*'],
    :relation => ['=', '=p', '=!p', '!p', '!*', '*'],
    :easy_lookup => ['=', '!']
  }

  def initialize(column, options={})
    @column = column
    super()
    merge!(options)
    self[:type] ||= :date_period if [:date, :datetime].include?(@column.type)
    if @column.name.ends_with?('_id')
      @association = options[:entity].reflect_on_all_associations(:belongs_to).detect{|as| as.foreign_key == @column.name }
      if @association
        self[:type] ||= :list
        unless self[:values]
          self[:values] = Proc.new do
            values = @association.klass.column_names.include?('position') ? @association.klass.order(:position) : @association.klass.all
            values = values.active if values.respond_to?(:active)
            values.collect{|r| [r.name, r.id] }
          end
        end
      end
    end
    self[:type] ||= @column.type
  end

  def <=>(other)
    self.order <=> other.order
  end

  def order
    self[:order] || 999
  end

  def values
    self[:values] = self[:values].is_a?(Proc) ? self[:values].call : self[:values]
  end

  def value(index = 0)
    (values || [])[index]
  end

  def valid?
    !([:list, :list_optional, :list_status, :list_subprojects].include?(self[:type]) && values.blank?)
  end

  def type
    self[:type]
  end

end


module EasyQueryParts
  module Filters

    def has_filter?(field)
      self.filters and self.filters[field]
    end

    def values_for(field)
      if self.has_filter?(field)
        self.filters[field][:values] || []
      else
        nil
      end
    end

    def value_for(field, index=0)
      (self.values_for(field) || [])[index]
    end

    def operator_for(field)
      self.has_filter?(field) ? self.filters[field][:operator] : nil
    end

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

    def default_filter
      {}
    end

    def filter_options(name, user=nil)
      opts = attribute_options(name, user)
      opts[:type] = opts.delete(:filter_type)
      opts
    end

    def available_filters
      return @available_filters if @available_filters
      @available_filters = {}
      entity.columns.each do |column|
        unless filter_options(column.name)[:reject]
          opts = {entity: self.entity}.merge(filter_options(column.name))
          @available_filters[column.name] = EasyQueryFilter.new(column, opts)
        end
      end
      @available_filters
    end

    def add_filter(field, operator, values)
      return if !self.available_filters.key?(field)
      values ||= []
      if values.is_a?(String)
        values = Array(values.force_encoding('UTF-8'))
      elsif values.is_a?(Array)
        values = values.flatten.collect { |x| x.force_encoding('UTF-8') if x.present? }.compact
      end
      self.filters[field] = {:operator => operator.to_s, :values => values}
    end

    def add_short_filter(field, expression)
      return unless expression && self.available_filters.has_key?(field)
      field_type = self.available_filters[field][:type]
      if field_type == :date_period
        e = expression.split('|')

        if e.size == 1
          if e[0].match(/\d{4}/) && (from_date = Date.parse(e[0]) rescue nil)
            self.add_filter(field, 'date_period_2', {:from => from_date, :to => from_date})
          else
            self.add_filter(field, 'date_period_1', self.get_date_range('1', e[0]).merge(:period => e[0]))
          end
        elsif e.size == 2 && e[0].include?('n_days')
          days = e[1].to_i
          self.add_filter(field, 'date_period_1', {:period => e[0], :period_days => days})
        elsif e.size == 2
          from_date = begin
            ; Date.parse(e[0]);
          rescue;
            nil;
          end unless e[0].blank?
          to_date = begin
            ; Date.parse(e[1]);
          rescue;
            nil;
          end unless e[1].blank?
          self.add_filter(field, 'date_period_2', {:from => from_date, :to => to_date})
        end
      else
        EasyQueryFilter.operators_by_filter_type[field_type].sort.reverse.detect do |operator|
          next unless expression =~ /^#{Regexp.escape(operator)}(.*)$/
          self.add_filter field, operator, $1.present? ? $1.split('|') : []
        end || self.add_filter(field, '=', expression.split('|'))
      end
    end

    # Add multiple filters using +add_filter+
    def add_filters(fields, operators, values)
      if fields.is_a?(Array) && operators.is_a?(Hash) && (values.nil? || values.is_a?(Hash))
        fields.each do |field|
          self.add_filter(field, operators[field], values && values[field])
        end
      end
    end


    # HACKING METHODS
    def extended_period_options
      {}
    end

  end
end
