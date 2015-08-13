module RedmineExtensions
  module ApplicationHelper

    # -------= Hack methods =------

    def plugin_settings_path(plugin, *attrs)
      if plugin.settings[:only_easy] || plugin.settings[:easy_settings]
        redmine_extensions_engine.edit_easy_setting_path(plugin, *attrs)
      else
        super
      end
    end

    # -------= Rendering and presenting methods =-------

    def hiearchy_for_ar(model)
      klass = model.class
      hiearchy = []
      while true
        hiearchy << klass.name
        break if klass == klass.base_class
        klass = klass.superclass
      end
      hiearchy
    end

    def render_with_fallback(*attrs)
      raise 'Missing an options argument' unless attrs.last.is_a?(Hash)
      options = attrs.last
      raise 'Missing an fallback prefixes' unless options[:prefixes]
      partial = options[:partial] || attrs.first
      prefixes = options.delete(:prefixes)

      prefixes = hiearchy_for_ar(prefixes).map{|klass| klass.underscore.pluralize } if prefixes.is_a?(ActiveRecord::Base)

      prefixes.each do |prefix|
        if lookup_context.template_exists?(partial, prefix, true)
          partial.prepend("#{prefix}/")
          return render(*attrs)
        end
      end
      partial.prepend("#{prefixes.last}/")
      render(*attrs)
    end

    def present(model, options={} &block)
      if model.is_a?(RedmineExtensions::BasePresenter)
        yield model.update_options(options.merge(view_context: self))
      else
        presenter_klass = nil
        hiearchy_for_ar(model).each do |klass|
          begin
            presenter_klass = "RedmineExtensions::#{klass}Presenter".constantize
            break
          rescue NameError
            next
          end
        end
        raise NameError, 'there is no presenter available for ' + model.class.name unless presenter_klass

        yield( presenter_klass.new(model, self, options) )
      end
    end

    # --- COMMON RENDERING ----

    # hide elements for issues and users
    def detect_hide_elements(uniq_id, user = nil, default = true)
      return ''.html_safe if uniq_id.blank?
      return 'style="display:none"'.html_safe if !toggle_button_expanded?(uniq_id, user, default)
    end

    def url_to_entity(entity, options={})
      m = "url_to_#{entity.class.name.underscore}".to_sym
      if respond_to?(m)
        send(m, entity, options)
      else
        nil
      end
    end

    def format_html_entity_attribute(entity_class, column, unformatted_value, options={})
      unformatted_value
    end

  end
end
