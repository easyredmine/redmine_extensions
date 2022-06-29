module RedmineExtensions
  module CustomFieldPatch

    def translated_name
      self.name
    end

  end
end

RedmineExtensions::PatchManager.register_model_patch 'CustomField', 'RedmineExtensions::CustomFieldPatch', if: -> { !Redmine::Plugin.installed?(:easy_extensions) }
