class EasySetting < ActiveRecord::Base

  belongs_to :project

  serialize :value

  validates :name, :presence => true
  attr_protected :id

  after_save :update_cache
  after_destroy :invalidate_cache

  def self.boolean_keys
    []
  end

  def self.copy_all_project_settings(source_project, target_project)
    source_project = source_project.id if source_project.is_a?(Project)
    target_project = target_project.id if target_project.is_a?(Project)

    options = {:scope => EasySetting.where(project_id: source_project)}
    Redmine::Hook.call_hook(:copy_all_project_settings_exceceptions, :options => options)
    source_project_names = options[:scope].pluck(:name)

    source_project_names.each do |name|
      copy_project_settings(name, source_project, target_project)
    end
  end

  def self.copy_project_settings(setting_name, source_project_id, target_project_id)
    source = EasySetting.where(:name => setting_name, :project_id => source_project_id).first
    target = EasySetting.where(:name => setting_name, :project_id => target_project_id).first

    if source.nil? && !target.nil?
      target.destroy
    elsif !source.nil? && target.nil?
      EasySetting.create(:name => setting_name, :project_id => target_project_id, :value => source.value)
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

  def self.value(key, project_or_project_id = nil, use_fallback = true)
    if project_or_project_id.is_a?(Project)
      project_id = project_or_project_id.id
    elsif !project_or_project_id.nil?
      project_id = project_or_project_id.to_i
    else
      project_id = nil
    end

    cache_key =  "EasySetting/#{key}/#{project_id}"
    fallback_cache_key = "EasySetting/#{key}/"

    cached_value = Rails.cache.fetch cache_key do
      EasySetting.where(name: key, project_id: project_id).pluck(:value).first
    end

    result = if use_fallback && (cached_value.nil? || cached_value == '')
        Rails.cache.fetch fallback_cache_key do
          EasySetting.where(name: key, project_id: nil).pluck(:value).first
        end
      else
        cached_value
      end
    result = plugin_defaults[key.to_s] if result.nil?
    result
  end

  def self.delete_key(key, project_or_project_id)
    if project_or_project_id.is_a?(Project)
      project_id = project_or_project_id.id
    elsif !project_or_project_id.nil?
      project_id = project_or_project_id.to_i
    else
      project_id = nil
    end
    return if project_id.nil?
    EasySetting.where(:name => key, :project_id => project_id).destroy_all
  end

  def self.get_beginning_of_fiscal_for_year(year = nil)
    f_y = year || Date.today.year
    f_m = (EasySetting.value('fiscal_month') || 1).to_i
    f_d = (EasySetting.value('fiscal_day') || 1).to_i

    begin
      Date.civil(f_y, f_m, f_d)
    rescue
      Date.civil(f_y, 1, 1)
    end
  end

  def self.beginning_of_fiscal_year(date = nil)
    today = date || Date.today
    fy = get_beginning_of_fiscal_for_year(today.year)

    if fy <= today
      fy
    else
      fy - 1.year
    end
  end

  def self.end_of_fiscal_year(date = nil)
    beginning_of_fiscal_year(date) + 1.year - 1.day
  end

  private

  def invalidate_cache
    Rails.cache.delete "EasySetting/#{self.name}/#{self.project_id}"
  end

  def update_cache
    Rails.cache.write "EasySetting/#{self.name}/#{self.project_id}", self.value
  end

end
