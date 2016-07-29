module RedmineExtensions
  class Hooks < Redmine::Hook::ViewListener

    def view_layouts_base_html_head(context={})
      if defined?(EasyExtensions)
        context[:hook_caller].javascript_include_tag('redmine_extensions/application')
      else
        javascript_include_tag('redmine_extensions/jquery.entityarray') +
        javascript_include_tag('redmine_extensions/redmine_extensions') +
        javascript_include_tag('redmine_extensions/easy_togglers')
      end

    end

  end
end
