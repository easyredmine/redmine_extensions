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

  class_attribute :hidden_values_by_operator
  self.hidden_values_by_operator = ['!*', '*', 't', 'w', 'o', 'c']

  attr_accessor :entity

  def initialize(column, options={})
    @column = column
    super()
    self.entity = options[:entity]
    merge!(options)
    self[:type] ||= :date_period if [:date, :datetime].include?(@column.type)
    if @column.name.ends_with?('_id')
      @association = self.entity.reflect_on_all_associations(:belongs_to).detect{|as| as.foreign_key == @column.name }
      if @association
        self[:type] ||= :list
        unless self[:values]
          self[:values] = Proc.new do
            values = @association.klass.column_names.include?('position') ? @association.klass.order(:position) : @association.klass.all
            values = values.active if values.respond_to?(:active)
            values.collect{|r| [(r.is_a?(Issue) ? r.subject : r.name), r.id] }
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


  def sql(field, operator, values)
    if field =~ /(.+)\.(.+)$/
      db_table = $1
      db_field = $2
    else
      db_table = self.entity.table_name
      db_field = field
    end
    returned_sql_for_field = self.sql_for_field(field, operator, values, db_table, db_field)
    '(' + returned_sql_for_field + ')' if returned_sql_for_field.present?
  end

  # Returns a SQL clause for a date or datetime field.
  def date_clause(table, field, from, to)
    s = []
    if from
      if from.is_a?(Date) || from.is_a?(Time)
        from = Time.local(from.year, from.month, from.day).yesterday.end_of_day
      else
        from = from - 1 # second
      end
      if EasyQuery.default_timezone == :utc
        from = from.utc
      end
      s << ("#{table}.#{field} > '%s'" % [EasyQuery.connection.quoted_date(from)])
    end
    if to
      if to.is_a?(Date) || to.is_a?(Time)
        to = Time.local(to.year, to.month, to.day).end_of_day
      end
      if EasyQuery.default_timezone == :utc
        to = to.utc
      end
      s << ("#{table}.#{field} <= '%s'" % [EasyQuery.connection.quoted_date(to)])
    end
    s.join(' AND ')
  end

  # Returns a SQL clause for a date or datetime field not in range.
  def reversed_date_clause(table, field, from, to)
    s = []
    if from
      from_yesterday = from - 1
      from_yesterday_time = Time.local(from_yesterday.year, from_yesterday.month, from_yesterday.day)
      if EasyQuery.default_timezone == :utc
        from_yesterday_time = from_yesterday_time.utc
      end
      s << ("#{table}.#{field} <= '%s'" % [EasyQuery.connection.quoted_date(from_yesterday_time.end_of_day)])
    end
    if to
      to_time = Time.local(to.year, to.month, to.day)
      if EasyQuery.default_timezone == :utc
        to_time = to_time.utc
      end
      s << ("#{table}.#{field} > '%s'" % [EasyQuery.connection.quoted_date(to_time.end_of_day)])
    end
    if s.empty?
      ''
    else
      '('+s.join(' OR ')+')'
    end
  end

  # Returns a SQL clause for a date or datetime field using relative dates.
  def relative_date_clause(table, field, days_from, days_to)
    date_clause(table, field, (days_from ? Date.today + days_from : nil), (days_to ? Date.today + days_to : nil))
  end

  # Helper method to generate the WHERE sql for a +field+, +operator+ and a +value+
  def sql_for_field(field, operator, value, db_table, db_field, is_custom_filter=false)
    operator = operator.to_s
    value = Array(value) if value.is_a?(String)
    sql = ''

    if db_table.blank?
      full_db_field_name = db_field
    else
      full_db_field_name = "#{db_table}.#{db_field}"
    end

    # sometimes operator is not saved
    if operator.blank? && value.is_a?(Hash) && value.key?(:period)
      if value[:period].blank?
        operator = 'date_period_2'
      else
        operator = 'date_period_1'
      end
    end

    case operator
      when '='
        if value.any?
          case self.type
            when :date, :date_past
              sql = date_clause(db_table, db_field, parse_date(value.first), parse_date(value.first))
            when :integer
              sql = "#{full_db_field_name} = #{value.first.to_i}"
            when :float
              float_val = value.first.to_f
              sql = "#{full_db_field_name} BETWEEN #{float_val - 1e-5} AND #{float_val + 1e-5}"
            when :boolean
              sql = "#{full_db_field_name} IN (#{(value.first.to_i == 1) ? EasyQuery.connection.quoted_true : EasyQuery.connection.quoted_false})"
            else
              sql = "#{full_db_field_name} IN (" + value.collect { |val| "'#{EasyQuery.connection.quote_string(val)}'" }.join(',') + ')'
              if value.size == 1 && value[0].blank?
                sql << " OR #{full_db_field_name} IS NULL"
              end
          end
        else
          # IN an empty set
          sql = '1=0'
        end
      when '!'
        if value.any?
          sql = "#{db_table}.#{db_field} NOT IN (" + value.collect { |val| "'#{EasyQuery.connection.quote_string(val)}'" }.join(',') + ')'
          if value.size == 1 && value[0].blank?
            sql << " OR #{full_db_field_name} IS NOT NULL"
          else
            sql << " OR #{full_db_field_name} IS NULL"
          end
        else
          # NOT IN an empty set
          sql = '1=1'
        end
      when '!*'
        sql = "#{full_db_field_name} IS NULL"
        sql << " OR #{full_db_field_name} = ''" if is_custom_filter
      when '*'
        sql = "#{full_db_field_name} IS NOT NULL"
        sql << " AND #{full_db_field_name} <> ''" if is_custom_filter
      when '>='
        if [:date, :date_past].include?(self.type)
          sql = date_clause(db_table, db_field, parse_date(value.first), nil)
        else
          if is_custom_filter
            sql = "CAST(#{full_db_field_name} AS decimal(60,3)) >= #{value.first.to_f}"
          else
            sql = "#{full_db_field_name} >= #{value.first.to_f}"
          end
        end
      when '<='
        if [:date, :date_past].include?(self.type)
          sql = date_clause(db_table, db_field, nil, parse_date(value.first))
        else
          if is_custom_filter
            sql = "CAST(#{full_db_field_name} AS decimal(60,3)) <= #{value.first.to_f}"
          else
            sql = "#{full_db_field_name} <= #{value.first.to_f}"
          end
        end
      when '><'
        if [:date, :date_past].include?(self.type)
          sql = date_clause(db_table, db_field, parse_date(value[0]), parse_date(value[1]))
        else
          if is_custom_filter
            sql = "CAST(#{full_db_field_name} AS decimal(60,3)) BETWEEN #{value[0].to_f} AND #{value[1].to_f}"
          else
            sql = "#{full_db_field_name} BETWEEN #{value[0].to_f} AND #{value[1].to_f}"
          end
        end
      when 'o'
        sql = "#{IssueStatus.table_name}.is_closed=#{EasyQuery.connection.quoted_false}" if field == "status_id"
      when 'c'
        sql = "#{IssueStatus.table_name}.is_closed=#{EasyQuery.connection.quoted_true}" if field == "status_id"
      when '><t-'
        # between today - n days and today
        sql = self.relative_date_clause(db_table, db_field, -value.first.to_i, 0)
      when '>t-'
        # >= today - n days
        sql = self.relative_date_clause(db_table, db_field, -value.first.to_i, nil)
      when '<t-'
        # <= today - n days
        sql = self.relative_date_clause(db_table, db_field, nil, -value.first.to_i)
      when 't-'
        # = n days in past
        sql = self.relative_date_clause(db_table, db_field, -value.first.to_i, -value.first.to_i)
      when '><t+'
        # between today and today + n days
        sql = self.relative_date_clause(db_table, db_field, 0, value.first.to_i)
      when '>t+'
        # >= today + n days
        sql = self.relative_date_clause(db_table, db_field, value.first.to_i, nil)
      when '<t+'
        # <= today + n days
        sql = self.relative_date_clause(db_table, db_field, nil, value.first.to_i)
      when 't+'
        # = today + n days
        sql = self.relative_date_clause(db_table, db_field, value.first.to_i, value.first.to_i)
      when 't'
        # = today
        sql = self.relative_date_clause(db_table, db_field, 0, 0)
      when 'w'
        # = this week
        first_day_of_week = EasyExtensions::Calendars::Calendar.first_wday
        day_of_week = Date.today.cwday
        days_ago = (day_of_week >= first_day_of_week ? day_of_week - first_day_of_week : day_of_week + 7 - first_day_of_week)
        sql = self.relative_date_clause(db_table, db_field, -days_ago, -days_ago + 6)
      when 'date_period_1'
        case value[:period].to_sym
          when :is_null
            sql = "#{full_db_field_name} IS NULL"
            sql << " OR #{full_db_field_name} = ''" if is_custom_filter
          when :is_not_null
            sql = "#{full_db_field_name} IS NOT NULL"
            sql << " OR #{full_db_field_name} <> ''" if is_custom_filter
          when :in_less_than_n_days
            operator = '<t+'
            sql = sql_for_field(field, operator, [value[:period_days]], db_table, db_field, is_custom_filter)
          when :in_more_than_n_days
            operator = '>t+'
            sql = sql_for_field(field, operator, [value[:period_days]], db_table, db_field, is_custom_filter)
          when :in_next_n_days
            operator = '><t+'
            sql = sql_for_field(field, operator, [value[:period_days]], db_table, db_field, is_custom_filter)
          when :in_n_days
            operator = 't+'
            sql = sql_for_field(field, operator, [value[:period_days]], db_table, db_field, is_custom_filter)
          when :less_than_ago_n_days
            operator = '>t-'
            sql = sql_for_field(field, operator, [value[:period_days]], db_table, db_field, is_custom_filter)
          when :more_than_ago_n_days
            operator = '<t-'
            sql = sql_for_field(field, operator, [value[:period_days]], db_table, db_field, is_custom_filter)
          when :in_past_n_days
            operator = '><t-'
            sql = sql_for_field(field, operator, [value[:period_days]], db_table, db_field, is_custom_filter)
          when :ago_n_days
            operator = 't-'
            sql = sql_for_field(field, operator, [value[:period_days]], db_table, db_field, is_custom_filter)
          else
            period_dates = RedmineExtensions::DateRange.new('1', value[:period], value[:from], value[:to])
            sql = self[:time_column] ?
              self.date_clause(db_table, db_field, (period_dates[:from].nil? ? nil : period_dates[:from].beginning_of_day), (period_dates[:to].nil? ? nil : period_dates[:to].end_of_day)) :
              self.date_clause(db_table, db_field, (period_dates[:from].nil? ? nil : period_dates[:from]), (period_dates[:to].nil? ? nil : period_dates[:to]))
        end
      when 'date_period_2'
        period_dates = RedmineExtensions::DateRange.new('2', value[:period], value[:from], value[:to])
        sql = self[:time_column] ?
          self.date_clause(db_table, db_field, (period_dates[:from].nil? ? nil : period_dates[:from].beginning_of_day), (period_dates[:to].nil? ? nil : period_dates[:to].end_of_day)) :
          self.date_clause(db_table, db_field, (period_dates[:from].nil? ? nil : period_dates[:from]), (period_dates[:to].nil? ? nil : period_dates[:to]))
      when '~'
        sql = "LOWER(#{db_table}.#{db_field}) LIKE '%#{EasyQuery.connection.quote_string(value.first.to_s.downcase)}%'"
      when '!~'
        sql = "LOWER(#{db_table}.#{db_field}) NOT LIKE '%#{EasyQuery.connection.quote_string(value.first.to_s.downcase)}%'"
      when '^~'
        sql = "LOWER(#{db_table}.#{db_field}) LIKE '#{EasyQuery.connection.quote_string(value.first.to_s.downcase)}%'"
      else
        raise "Unknown query operator #{operator}"
    end

    return sql
  end

end

class EasyQueryCustomFilter

  def sql(field, operator, values)
    self.sql_for_custom_field(field, operator, values, $1)
  end

  def sql_for_custom_field(field, operator, value, custom_field_id)
    operator = operator.to_s
    db_table = CustomValue.table_name
    db_field = 'value'
    db_entity = self.entity
    db_entity_table_name = db_entity.table_name
    filter = self.available_filters[field]

    return nil unless filter

    if filter[:field].format.target_class && filter[:field].format.target_class <= User
      if value.delete('me')
        value.push User.current.id.to_s
      end
    end

    not_in = nil

    if operator == '!'
      # Makes ! operator work for custom fields with multiple values
      operator = '='
      not_in = 'NOT'
    end

    customized_key = 'id'
    customized_class = entity

    if field =~ /^(.+)_cf_/
      assoc = $1

      assoc_klass = entity.reflect_on_association(assoc.to_sym)
      customized_class = assoc_klass.klass.base_class rescue nil

      if customized_class && assoc_klass.collection?
        db_entity_table_name = assoc
        customized_key = 'id'
      else
        customized_key = "#{assoc}_id"
      end

      raise "Unknown Entity association #{assoc}" unless customized_class
    end

    where = sql_for_field(field, operator, value, db_table, db_field, true)

    if operator =~ /[<>]/
      where = "(#{where}) AND " if where.present?
      where << "#{db_table}.#{db_field} <> ''"
    end

    sql = "#{db_entity_table_name}.#{customized_key} #{not_in} IN (" +
      "SELECT #{customized_class.table_name}.id FROM #{customized_class.table_name}" +
      " LEFT OUTER JOIN #{db_table} ON #{db_table}.customized_type='#{customized_class}' AND #{db_table}.customized_id=#{customized_class.table_name}.id AND #{db_table}.custom_field_id=#{custom_field_id} WHERE"
    sql << " (#{where}) AND" if where.present?
    sql << " (#{filter[:field].visibility_by_project_condition}))"
    sql
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
          case self.type
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
            self.add_filter(field, 'date_period_1', RedmineExtensions::DateRange.new('1', e[0]).merge(:period => e[0]))
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
