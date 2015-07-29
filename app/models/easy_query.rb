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

  include EasyQueryParts::Columns
  include EasyQueryParts::Filters
  include EasyQueryParts::Groupable
end

begin
  require_dependency Rails.root.join('plugins', 'easyproject', 'easy_plugins', 'easy_extensions', 'app', 'models', 'easy_queries', 'easy_query')
rescue LoadError
  Rails.logger.warn 'EasyRedmine is not installed, please visit a easyredmine.com and consider installation.'
end
