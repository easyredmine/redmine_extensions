module RedmineExtensions
  class EasySetting < ActiveRecord::Base
    belongs_to :project

    def self.value(name, project=nil)
      setting = self.where(name: name, project_id: project ).first
      setting ||= self.where(name: name).first

      setting.value if setting
    end
  end
end
