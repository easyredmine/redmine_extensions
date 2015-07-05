module RedmineExtensions
  module HTMLFormatting
    module Helper

      def wikitoolbar_for(field_id, options={})
        heads_for_wiki_formatter

        custom_settings = options.delete(:custom)
        options[:toolbar] ||= EasySetting.value('ckeditor_toolbar_config') || 'Basic'
        options[:lang] ||= User.current.language
        options[:lang] = Setting.default_language if options[:lang].blank?
        options[:language] = options[:lang] if options[:lang].present?

        # Syntax higlight
        if EasySetting.value('ckeditor_syntax_highlight_enabled')
          options[:codeSnippet_theme] ||= EasyCKEditor.syntaxt_higlight_template
        else
          if options[:removePlugins]
            options[:removePlugins] << ','
          else
            options[:removePlugins] = ''
          end

          options[:removePlugins] << 'codesnippet'
        end

        hook_settings = call_hook(:helper_ckeditor_wikitoolbar_for_add_option, {:field_id => field_id, :options => options})

        ck_options = options.collect{|k,v| "#{k}:'#{v}'"}
        ck_options << custom_settings unless custom_settings.blank?
        ck_options << hook_settings unless hook_settings.to_s.blank?

        reminder_confirm = options[:attachment_reminder_message] ? options[:attachment_reminder_message] : l(:text_easy_attachment_reminder_confirm)
        reminderjs = options[:attachment_reminder] ? "$('##{field_id}').addClass('set_attachment_reminder').data('ck', true).data('reminder_words', \"#{j(Attachment.attachment_reminder_words)}\").data('reminder_confirm', '#{j(reminder_confirm)}'); " : ''

        js = "var ta_editor = CKEDITOR.instances['#{field_id}']; if (ta_editor) {CKEDITOR.remove(ta_editor);} CKEDITOR.replace('#{field_id}',{#{ck_options.join(',')}});"
        js << "window.enableWarnLeavingUnsaved = '#{User.current.pref.warn_on_leaving_unsaved}';"

        javascript_tag(reminderjs + js)
      end

      def initial_page_content(page)
      end

      def heads_for_wiki_formatter
        unless @heads_for_wiki_formatter_included
          header = javascript_include_tag('redmine_extensions/ckeditor/ckeditor')

          # Syntax higlight
          if EasySetting.value('ckeditor_syntax_highlight_enabled')
            header << stylesheet_link_tag(EasyCKEditor.syntaxt_higlight_css)
            header << javascript_include_tag(EasyCKEditor.syntaxt_higlight_js)

            # Pre block have custom css attributes
            # .pre-hljs will set them to default
            header << javascript_tag(%{
              $(document).ready(function() {
                $('pre code').each(function(i, block) {
                  hljs.highlightBlock(block);
                  $(block).parent().addClass('pre-default');
                });
              });
            })
          end

          content_for(:header_tags, header)
          @heads_for_wiki_formatter_included = true
        end

      end
    end
  end
end
