module RedmineExtensions
  class EasySettingsPresenter < BasePresenter

    attr_accessor :project, :plugin

    BOOLEAN_KEYS =
      [:project_calculate_start_date, :project_calculate_due_date, :timelog_comment_editor_enabled,
        :time_entry_spent_on_at_issue_update_enabled, :commit_logtime_enabled, :project_fixed_activity,
        :enable_activity_roles, :show_issue_id, :commit_cross_project_ref, :issue_recalculate_attributes,
        :quick_jump_to_an_issue, :use_easy_cache, :avatar_enabled, :show_personal_statement, :show_bulk_time_entry,
        :enable_private_issues, :use_personal_theme, :display_issue_relations_on_new_form, :milestone_effective_date_from_issue_due_date,
        :allow_log_time_to_closed_issue, :project_display_identifiers, :issue_set_done_after_close, :allow_repeating_issues,
        :just_one_issue_mail, :required_issue_id_at_time_entry, :close_subtask_after_parent, :show_time_entry_range_select,
        :easy_contact_toolbar_is_enabled, :issue_private_note_as_default, :show_easy_resource_booking,
        :skip_workflow_for_admin, :hide_login_quotes, :display_project_field_on_issue_detail,
        :easy_invoicing_use_estimated_time_for_issues, :hide_imagemagick_warning,
        :time_entries_locking_enabled,
        :easy_webdav_enabled,
        :show_avatars_on_query,
        :easy_user_allocation_by_project_enabled,
        :ckeditor_syntax_highlight_enabled
      ]

    def initialize(settings_params={}, project = nil)
      @settings = settings_params || {}
      @settings = @settings.dup.symbolize_keys
      super(EasySetting.new, nil)
    end

    def plugin=(plugin)
      @plugin = plugin
      self.model = plugin
    end

    def unsaved_settings
      @unsaved_settings ||= []
    end

    def persisted?
      !!@plugin
    end

    def id
      @plugin && @plugin.id
    end

    def prefix
      @plugin && (@plugin.id.to_s + '_') || ''
    end

    # TODO: form rendering methods. Maybe push them to the parent?
    def to_model
      self
    end
    def model_name
      EasySetting.model_name
    end
    def param_key
      EasySetting.param_key
    end
    def to_key
      @plugin && [@plugin.id]
    end

    # TODO - more dynamic solution?
    def boolean_keys
      from_easy_setting = EasySetting.boolean_keys
      ActiveSupport::Deprecation.warn("EasySetting.boolean_keys has been deprecated, use EasySettingsPresenter#boolean_keys instead") if from_easy_setting.any?
      from_easy_setting.concat(BOOLEAN_KEYS)
    end

    def save
      project_id = project.try(:id)
      unsaved_settings.clear
      valid = true
      @settings.each do |name, value|
        # remove blank values in array settings
        value.delete_if{|v| v.blank? } if value.is_a?(Array)
        name = prefix+name.to_s

        set = EasySetting.where(name: name.to_s, project_id: project_id).first || EasySetting.new(name: name.to_s, project_id: project_id)

        set.value = case name.to_sym
        when *boolean_keys
          value.to_boolean
        when :attachment_description
          esa = EasySetting.where(:name => 'attachment_description_required', :project_id => nil).first
          case value
          when 'required'
            esa.update_attribute(:value, true)
            true
          when '1'
            esa.update_attribute(:value, false)
            true
          else
            esa.update_attribute(:value, false)
            false
          end
        when :agile_board_statuses
          value[:progress] = value.delete('progress') if value["progress"]
          value[:done] = value.delete('done') if value["done"]
          value
        else
          value
        end
        valid &&= set.save
        unsaved_settings << set unless set.persisted?
      end
      valid
    end

    def method_missing(meth, *attrs)
      if @plugin && @plugin.settings[:easy_settings] && @plugin.settings[:easy_settings].keys.include?(meth.to_sym)
        EasySetting.value(prefix+meth.to_s, project)
      else
        super
      end
    end

  end
end
