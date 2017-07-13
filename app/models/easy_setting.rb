##
# EasySetting
#
# == Mapping
# type::
#   boolean, integer, float
#   (default: none)
#
# default::
#   (default: nil)
#
# from_params::
#   Accept lambda with one argument for raw_value (from params)
#   (default: none)
#
# validate::
#   Accept block which will be trigered in EasySetting instance
#   (default: none)
#
# disabled_from_params::
#   (default: false)
#
# after_save::
#   Accept block which will be trigered in EasySetting instance
#   (default: none)
#
# == Mapping examples
#
#   EasySetting.map do
#
#     # Integer key
#     key :integer_key do
#       type 'integer'
#       default 42
#
#       validate { errors.add(:value, 'Bad range') if value < 0 || value > 500 }
#       after_save { Mailer.integer_key_changed }
#     end
#
#     # Custom definition
#     key :custom_key do
#       default 'Ondra'
#       from_params lambda {|v| v.to_s }
#     end
#
#     # Cannot be changed via params
#     key :not_from_params do
#       default 'Ondra'
#       disabled_from_params
#     end
#
#   end
#
#   # Boolean key definition
#   EasySetting.map.key(:boolean_key, type: 'boolean')
#
#   # Multiple defintions
#   EasySetting.map.keys(:key1, :key2, :key3, disabled_from_params: true)
#
class EasySetting < ActiveRecord::Base

  belongs_to :project

  validates :name, presence: true
  validate :mapper_validate

  after_save :update_cache
  after_save :mapper_after_save
  after_destroy :invalidate_cache

  attr_protected :id
  serialize :value

  @@mapper = EasySettings::Mapper.new

  def self.map(&block)
    if block_given?
      @@mapper.instance_eval(&block)
    else
      @@mapper
    end
  end

  def self.mapper_defaults
    @mapper_defaults ||= @@mapper.default_values
  end

  def self.mapper_clear_caches
    @mapper_defaults = nil
  end

  def mapper_after_save
    @@mapper.after_save(self)
  end

  def mapper_validate
    @@mapper.validate(self)
  end

  def from_params(value)
    return if disabled_from_params?
    self.value = @@mapper.from_params(self, value)
  end

  def disabled_from_params?
    @@mapper.disabled_from_params?(self)
  end

  def self.boolean_keys
    []
  end

  def self.copy_all_project_settings(source_project, target_project)
    source_project = source_project.id if source_project.is_a?(Project)
    target_project = target_project.id if target_project.is_a?(Project)

    options = { scope: EasySetting.where(project_id: source_project) }
    Redmine::Hook.call_hook(:copy_all_project_settings_exceceptions, options: options)
    source_project_names = options[:scope].pluck(:name)

    source_project_names.each do |name|
      copy_project_settings(name, source_project, target_project)
    end
  end

  def self.copy_project_settings(setting_name, source_project_id, target_project_id)
    source = EasySetting.find_by(name: setting_name, project_id: source_project_id)
    target = EasySetting.find_by(name: setting_name, project_id: target_project_id)

    if source.nil? && !target.nil?
      target.destroy
    elsif !source.nil? && target.nil?
      EasySetting.create(name: setting_name, project_id: target_project_id, value: source.value)
    elsif !source.nil? && !target.nil? && target.value != source.value
      target.value = source.value
      target.save
    end
  end

  def self.plugin_defaults
    @plugin_defaults ||= Redmine::Plugin.all.inject({}) do |res, p|
      if p.settings && p.settings[:easy_settings].is_a?(Hash)
        p.settings[:easy_settings].each do |key, value|
          res["#{p.id}_#{key}"] = value
        end
      end
      res
    end
  end

  def self.value(key, project = nil, use_fallback = true)
    if project.is_a?(Project)
      project_id = project.id
    elsif project.present?
      project_id = project.to_i
    else
      project_id = nil
    end

    cache_key = "EasySetting/#{key}/#{project_id}"
    fallback_cache_key = "EasySetting/#{key}/"

    result = Rails.cache.fetch(cache_key) do
      EasySetting.where(name: key, project_id: project_id).limit(1).pluck(:value).first
    end

    if use_fallback && result.blank?
      result = Rails.cache.fetch(fallback_cache_key) do
        EasySetting.where(name: key, project_id: nil).limit(1).pluck(:value).first
      end
    end

    result = plugin_defaults[key.to_s] if result.nil?
    result = mapper_defaults[key.to_s] if result.nil?
    result
  end

  def self.delete_key(key, project)
    if project.is_a?(Project)
      project_id = project.id
    elsif project.present?
      project_id = project.to_i
    else
      project_id = nil
    end

    return if project_id.nil?
    EasySetting.where(name: key, project_id: project_id).destroy_all
  end

  # TODO: Move away
  def self.get_beginning_of_fiscal_for_year(year = nil)
    f_y = year || Date.today.year
    f_m = (EasySetting.value('fiscal_month') || 1).to_i
    f_d = 1

    begin
      Date.civil(f_y, f_m, f_d)
    rescue
      Date.civil(f_y, 1, 1)
    end
  end

  # TODO: Move away
  def self.beginning_of_fiscal_year(date = nil)
    today = date || Date.today
    fy = get_beginning_of_fiscal_for_year(today.year)

    if fy <= today
      fy
    else
      fy - 1.year
    end
  end

  # TODO: Move away
  def self.end_of_fiscal_year(date = nil)
    beginning_of_fiscal_year(date) + 1.year - 1.day
  end

  private

    def invalidate_cache
      Rails.cache.delete("EasySetting/#{name}/#{project_id}")
    end

    def update_cache
      Rails.cache.write("EasySetting/#{name}/#{project_id}", value)
    end

end

EasySetting.map do

  key :easy_gantt_ondra1 do
    type 'integer'

    after_save { binding.pry }
    validate { binding.pry }
  end

  key :easy_gantt_ondra2 do
    default "ondra2"

    from_params lambda {|v| binding.pry; v }
    after_save { binding.pry }
    validate {  binding.pry }
  end

  key :easy_gantt_ondra3 do
    disabled_from_params
    default "ondra3 default"
  end

end
