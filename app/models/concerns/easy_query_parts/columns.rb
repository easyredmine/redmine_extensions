class EasyQueryColumn < EasyEntityAttribute

  # sumable => :top || :bottom || :both
  attr_accessor :sortable, :groupable, :default_order, :assoc, :sumable_sql

  def initialize(name, options={})
    if name.is_a?(ActiveRecord::ConnectionAdapters::Column)
      @column = name
      name = @column.name.to_sym
      options[:type] = @column.type
      if @column.name.ends_with?('_id')
        @association = options[:entity].reflect_on_all_associations(:belongs_to).detect{|as| as.foreign_key == @column.name }
        @assoc = @association && @association.name
      end
    end

    super(name, options)
    self.sortable = options[:sortable].is_a?(Proc) ? options[:sortable].call : options[:sortable]
    self.groupable = options[:groupable] || false
    if groupable == true
      if self.sortable.is_a?(String)
        self.groupable = self.sortable
      else
        self.groupable = name.to_s
      end
    end
    self.default_order = options[:default_order]
    self.sumable_sql = options[:sumable_sql]
    @sumable = options[:sumable]
  end

  def polymorphic?
    assoc && !!@association.options[:polymorphic]
  end

  def sortable?
    !sortable.nil?
  end

  def assoc_column?
    @assoc.present?
  end

  # TODO: deprecate and ask the type
  def date?
    false
  end

  def sumable_top?
    @sumable == :top || @sumable == :both
  end

  def additional_joins(entity_cls, type=nil)
    self.joins
  end

  def sumable_bottom?
    @sumable == :bottom || @sumable == :both
  end

  def sum(query, options={})
    scope = query.merge_scope(query.new_entity_scope, options).joins(additional_joins(query.entity))
    if @association
      raise NotImplemented if polymorphic?
      @association.class_name.constantize.where(id: scope.pluck(@association.foreign_key)).sum(self.name)
    else
      scope.sum(self.sumable_sql || self.name)
    end
  end
end
module EasyQueryParts
  module Columns
    extend ActiveSupport::Concern

    included do
      attr_accessor :display_project_column_if_project_missing
    end


    def load_entity_columns
      result = []
      entity.columns.each do |column|
        result << EasyQueryColumn.new(column, {entity: self.entity}.merge(attribute_options(column.name)) ) unless attribute_options(column.name)[:reject]
      end
      result
    end


    def add_associated_columns(easy_query_class, options ={})
      @available_columns ||= []
      q = easy_query_class.new

      association_name = options[:association_name] || q.entity.name.underscore.to_sym
      column_name_prefix = options[:column_name_prefix] || "#{association_name}."

      q.available_columns.each do |origin_column|
        next if origin_column.assoc_column? && !options[:all]

        new_column = origin_column.dup
        new_column.name = "#{column_name_prefix}#{origin_column.name}".to_sym

        if origin_column.caption.to_s =~ /\A.+ \(.+\)\z/
          new_column.title = origin_column.caption
        else
          new_column.title = "#{origin_column.caption} (#{q.default_name})"
        end

        new_column.assoc = association_name

        new_column.includes = Array.wrap(new_column.includes).map {|i| {association_name => i}} << association_name
        new_column.preload = (Array.wrap(new_column.preload).map {|i| {association_name => i}} << association_name) if !new_column.preload.blank?
  #      new_column.joins = (Array.wrap(new_column.joins).map {|i| {association_name => i}} << association_name) if !new_column.joins.blank?

        @available_columns << new_column
      end

      @available_columns
    end

    def columns_from_associations
      []
    end

    def available_columns
      return @available_columns if @available_columns
      @available_columns = load_entity_columns
    end

    # Returns an array that can be shown to user or current user
    #
    # Example:
    #   book_query.attributes_options('title') # => {reject: true, ...}
    #   book_query.attributes_options(:title, User.find_by(admin: true))  # => {rejected: false}
    def attribute_options(attribute, user=nil)
      attribute = attribute.to_sym
      return @attributes_options[attribute] || {} if @attributes_options && user.nil?
      attrs_options = {}
      self.class.attributes_options.each do |attrs, options|
        options.keys.each do |key|
          options[key] = options[key].call(self, user || User.current) if options[key].respond_to?(:call)
        end
        attrs.each do |a|
          a = a.to_sym
          attrs_options[a.to_sym] ||= {}
          attrs_options[a.to_sym].merge!(options)
        end
      end
      @attributes_options = attrs_options if user.nil?
      attrs_options[attribute] || {}
    end

    def default_list_columns
      Array.new
    end

    def has_default_columns?
      self.column_names.blank?
    end

    def columns_with_me
      ['assigned_to_id', 'author_id', 'watcher_id']
    end

    # Returns an array of columns that can be used to group the results
    def groupable_columns
      self.available_columns.select { |c| c.groupable }
    end

    def sumable_columns
      available_columns.select { |c| c.sumable_top? || c.sumable_bottom? }.uniq
    end

    def sumable_columns?
      sumable_columns.any?
    end

    def inline_columns
      @inline_columns ||= columns.select { |c| c.inline? && c.visible? }
    end

    def block_columns
      @block_columns ||= columns.select { |c| !c.inline? && c.visible? }
    end


    def column(name)
      self.available_columns.detect { |c| c.name.to_s == name }
    end

    def columns
      columns = if self.has_default_columns?
                  def_columns = []
                  if self.display_project_column_if_project_missing && self.project.nil? && (project_column = self.available_columns.detect { |c| c.name == :project })
                    def_columns << project_column
                  end
                  self.default_list_columns.each { |cname| def_columns << self.column(cname) }
                  def_columns.compact.uniq
                else
                  # preserve the column_names order
                  self.column_names.collect do |name|
                    self.available_columns.detect { |col| col.name == name }
                  end.compact
                end

      return columns
    end

    def column_names=(names)
      if names
        names = names.select { |n| n.is_a?(Symbol) || !n.blank? }
        names = names.collect { |n| n.is_a?(Symbol) ? n : n.to_sym }
        # Set column_names to nil if default columns
        if names.map(&:to_s) == self.default_list_columns
          names = nil
        end
      end
      write_attribute(:column_names, names)
    end

    module ClassMethods

      # Through this method you can specify an attributes options
      # special options are: rejected
      def attributes_options(*args)
        @attributes_options ||= []
        if args.empty?
          if superclass.include?(EasyQueryParts::Columns)
            @attributes_options + superclass.attributes_options
          else
            @attributes_options
          end
        else
          options = args.last.is_a?(Hash) ? args.pop : {}
          @attributes_options << [args, options]
        end
      end

    end

  end
end
