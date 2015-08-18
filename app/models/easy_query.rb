class EasyQuery < ActiveRecord::Base

  class StatementInvalid < ::ActiveRecord::StatementInvalid
  end

  VISIBILITY_PRIVATE = 0
  VISIBILITY_ROLES = 1
  VISIBILITY_PUBLIC = 2

  belongs_to :project
  belongs_to :user
  has_and_belongs_to_many :roles, :join_table => "#{table_name_prefix}easy_queries_roles#{table_name_suffix}", :foreign_key => 'easy_query_id'

  serialize :filters, Hash
  serialize :column_names, Array
  serialize :sort_criteria, Array
  serialize :outputs, Array
  serialize :settings, Hash

  validates :name, :presence => true, :on => :save
  validates_length_of :name, :maximum => 255
  validates :visibility, :inclusion => {:in => [VISIBILITY_PUBLIC, VISIBILITY_ROLES, VISIBILITY_PRIVATE]}
  validate :validate_query_filters #defined in filters module
  validate do |query|
    errors.add(:base, l(:label_role_plural) + ' ' + l('activerecord.errors.messages.blank')) if query.visibility == VISIBILITY_ROLES && roles.blank?
  end

  after_save do |query|
    if query.visibility_changed? && query.visibility != VISIBILITY_ROLES
      query.roles.clear
    end
  end

  def entity
    raise NotImplementedError.new('entity method has to be implemented in EasyQuery ancestor: ' + self.class.name)
  end

  def entity_scope=(scope)
    @entity_scope = scope
  end

  def entity_scope
    if !@entity_scope.nil?
      @entity_scope
    elsif self.entity.respond_to?(:visible)
      self.entity.visible
    else
      self.entity
    end
  end

  def entity_count(options={})
    super
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # Returns a Hash of columns and the key for sorting
  def sortable_columns
    self.available_columns.inject({}) { |h, column|
      h[column.name.to_s] = column.sortable
      h
    }
  end

  # return type = :sql || :array
  def joins_for_order_statement(order_options, return_type = :sql)

    joins = []

    order_options.scan(/cf_\d+/).uniq.each do |name|
      column = available_columns.detect { |c| c.name.to_s == name }
      join = column && column.additional_joins(self.entity, return_type)
      joins.concat(join) if join
    end if order_options

    additional_joins = Array.wrap(add_additional_order_statement_joins(order_options))
    joins.concat(additional_joins) if additional_joins.present?

    case return_type
      when :sql
        joins.any? ? joins.join(' ') : nil
      when :array
        joins
      else
        raise ArgumentError, 'return_type has to be either :sql or :array'
    end
  end

  def add_additional_order_statement_joins(order_options)
    ''
  end

  def default_find_include
    []
  end

  def default_find_joins
    []
  end

  def default_find_preload
    []
  end

  def sort_criteria_to_sql_order(criterias=sort_criteria)
    sortable_columns_sql = self.available_columns.select { |c| c.sortable? }.inject({}) { |h, c| h[c.name.to_s] = c.sortable; h }
    criterias.select { |field_name, asc_desc| !!sortable_columns_sql[field_name] }.collect { |field_name, asc_desc| (sortable_columns_sql[field_name].is_a?(Array) ? sortable_columns_sql[field_name].join(" #{asc_desc}, ") : sortable_columns_sql[field_name]) + ' ' + (asc_desc || 'asc') }.join(', ')
  end

  def entity_sum(*attrs)
    super
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  include EasyQueryParts::Entities
  include EasyQueryParts::Columns #define column methods - available_columns, column options
  include EasyQueryParts::CustomFields
  include EasyQueryParts::Filters
  include EasyQueryParts::Settings
  include EasyQueryParts::Groupable
  include EasyQueryParts::Summable
  include EasyQueryParts::Statement
  include EasyQueryParts::Searchable
  include EasyQueryParts::Deprecated # to_params, from_params
end

begin
  require_dependency Rails.root.join('plugins', 'easyproject', 'easy_plugins', 'easy_extensions', 'app', 'models', 'easy_queries', 'easy_query')
rescue LoadError
  Rails.logger.warn 'EasyRedmine is not installed, please visit a www.easyredmine.com for feature preview and consider installation.'
end
