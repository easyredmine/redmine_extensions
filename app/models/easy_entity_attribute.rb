class EasyEntityAttribute
  include Redmine::I18n

  attr_accessor :name, :no_link, :includes, :joins, :preload, :type, :title

  def initialize(*attrs)
    options = attrs.last.is_a?(Hash) ? attrs.pop : {}
    name = attrs.shift
    self.name = name.to_sym
    @type = options[:type]
    @caption_key = options[:caption] || "field_#{name}"
    @title = options[:title]
    @no_link = options[:no_link].nil? ? false : options[:no_link]
    @inline = options.key?(:inline) ? options[:inline] : true
    @full_rows_column = options[:full_rows_column].nil? ? false : options[:full_rows_column]
    @includes = options[:includes]
    @joins = Array(options[:joins])
    @preload = options[:preload]
  end

  def caption(with_suffixes=false)
    @title || l(@caption_key)
  end

  def inline?
    @inline
  end

  def visible?
    true
  end

  def numeric?
    [:integer].include?(type)
  end

  def full_rows_column?
    self.inline? && @full_rows_column
  end

  def value(entity, options={})
    entity.nested_send(self.name)
  end

  def value_object(entity, options={})
    self.value(entity, options)
  end

  def css_classes
    @css_classes ||= [self.name.to_s.underscore, (self.numeric? ? 'right-alignment' : '')].reject(&:blank?).join(' ')
  end

end
