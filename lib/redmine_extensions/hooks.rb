module RedmineExtensions
  class Hooks < Redmine::Hook::ViewListener

    if Rails.env.development?
      render_on :view_layouts_base_body_bottom, partial: 'redmine_extensions/development_mode'
    end

    if defined?(EasyExtensions)
      if EasyExtensions.try(:deferred_js)

        ### DEFERRED JAVASCRIPTS ###
        def easy_extensions_blocking_javascripts_hook(context = {})
          context[:template].require_asset('redmine_extensions/blocking')
        end

        def easy_extensions_javascripts_hook(context = {})
          context[:template].require_asset('redmine_extensions/application')
        end
      else
        ### JAVASCRIPTS IN HEADER ###
        def easy_extensions_javascripts_hook(context = {})
          context[:template].require_asset('redmine_extensions/blocking')
          context[:template].require_asset('redmine_extensions/application')
        end
      end
      if Rails.env.development? || Rails.env.test?
        render_on :view_layouts_base_html_head, partial: 'redmine_extensions/jasmine'
      end
    else
      ### JAVASCRIPTS IN REDMINE ###
      def view_layouts_base_html_head(context = {})
        ## BLOCKING ##
        javascript_include_tag('redmine_extensions/blocking_namespace') +
          javascript_include_tag('redmine_extensions/blocking_schedule') +
          javascript_include_tag('redmine_extensions/blocking_module') +
          javascript_include_tag('redmine_extensions/blocking_polyfill') +
          javascript_include_tag('redmine_extensions/blocking_render') +
          javascript_include_tag('redmine_extensions/blocking_utils') +
          javascript_include_tag('redmine_extensions/blocking_dynamic_loading') +

          ## DEFERRED ##
          javascript_include_tag('redmine_extensions/easy_togglers') +
          javascript_include_tag('redmine_extensions/jquery.entityarray') +
          javascript_include_tag('redmine_extensions/render_polyfill') +
          javascript_include_tag('redmine_extensions/redmine_extensions') +
          (context[:controller].send(:render_to_string, partial: 'redmine_extensions/jasmine') if Rails.env.development? || Rails.env.test?)
      end
    end

  end
end
