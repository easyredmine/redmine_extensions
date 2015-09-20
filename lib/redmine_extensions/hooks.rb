module RedmineExtensions
  class Hooks < Redmine::Hook::ViewListener

    def view_layouts_base_html_head(context={})
      javascript_include_tag('redmine_extensions/redmine_extensions')
    end

  end
end
