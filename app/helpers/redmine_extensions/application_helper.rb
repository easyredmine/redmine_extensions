module RedmineExtensions
  module ApplicationHelper
    include RenderingHelper

    # -------= Hack methods =------

    def plugin_settings_path(plugin, *attrs)
      if plugin.settings[:only_easy] || plugin.settings[:easy_settings]
        redmine_extensions_engine.edit_easy_setting_path(plugin, *attrs)
      else
        super
      end
    end

    # -------= Rendering and presenting methods =-------

    def present(model, options={}, &block)
      if model.is_a?(RedmineExtensions::BasePresenter)
        presenter = model.update_options(options.merge(view_context: self))
      else
        presenter = RedmineExtensions::BasePresenter.present(model, self, options)
      end
      if block_given?
        yield presenter
      else
        presenter
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

    # Dummy multiselect for pure redmine
    def easy_multiselect_tag(name, possible_values, selected_values, options={})
      select_tag(name, options_for_select(possible_values, selected_values.try(:first)), options)
    end

    # Return *true* if item can be added to select
    def eqeoc(key, field, options)
      options ||= {}
      return false if options[:field_disabled_options] && [options[:field_disabled_options][field]].flatten.include?(key)
      return (options[:extended_options] && options[:extended_options].include?(key)) ||
        ((options[:option_limit] && options[:option_limit][key] && options[:option_limit][key].include?(field)))
    end

    # return options for date and datetime select in easy_query
    def options_for_period_select(value, field=nil, options={})
      no_category = [
        [l(:label_all_time), 'all']
      ]

      past_items = [
        [l(:label_yesterday), 'yesterday'],
        [l(:label_last_week), 'last_week'],
        [l(:label_last_n_weeks, 2), 'last_2_weeks'],
        [l(:label_last_n_days, 7), '7_days'],
        [l(:label_last_month), 'last_month'],
        [l(:label_last_n_days, 30), '30_days'],
        [l(:label_last_n_days, 90), '90_days'],
        [l(:label_last_year), 'last_year'],
        [l(:label_older_than_n_days, 14), 'older_than_14_days'],
        [l(:label_older_than_n_days, 15), 'older_than_15_days'],
        [l(:label_older_than_n_days, 31), 'older_than_31_days']
      ]

      present_items = [
        [l(:label_today), 'today'],
        [l(:label_this_week), 'current_week'],
        [l(:label_this_month), 'current_month'],
        [l(:label_this_year), 'current_year'],
        [l(:label_last_n_days_next_m_days, :last => 30, :next => 90), 'last30_next90']
      ]

      if options[:disabled_values].is_a? Array
        no_category.delete_if { |item| options[:disabled_values].include?(item[1]) }
        past_items.delete_if { |item| options[:disabled_values].include?(item[1]) }
        present_items.delete_if { |item| options[:disabled_values].include?(item[1]) }
      end

      future_items = Array.new
      if field || options[:show_future]
        no_category << [l(:label_is_null), 'is_null'] if field && eqeoc(:is_null, field, options)
        no_category << [l(:label_is_not_null), 'is_not_null'] if field && eqeoc(:is_not_null, field, options)
        present_items << [l(:label_to_today), 'to_today'] if field && eqeoc(:to_today, field, options)
        # future stuff
        future_items << [l(:label_tomorrow), 'tomorrow'] if options[:show_future] || eqeoc(:tomorrow, field, options)
        future_items << [l(:label_from_tomorrow), 'from_tomorrow'] if options[:show_future] || eqeoc(:from_tomorrow, field, options)
        future_items << [l(:label_next_week), 'next_week'] if options[:show_future] || eqeoc(:next_week, field, options)
        future_items << [l(:label_next_n_days, :days => 5), 'next_5_days'] if options[:show_future] || eqeoc(:next_5_days, field, options)
        future_items << [l(:label_next_n_days, :days => 7), 'next_7_days'] if options[:show_future] || eqeoc(:next_7_days, field, options)
        future_items << [l(:label_next_n_days, :days => 10), 'next_10_days'] if options[:show_future] || eqeoc(:next_10_days, field, options)
        future_items << [l(:label_next_n_days, :days => 14), 'next_14_days'] if options[:show_future] || eqeoc(:next_14_days, field, options)
        future_items << [l(:label_next_n_days, :days => 15), 'next_15_days'] if options[:show_future] || eqeoc(:next_15_days, field, options)
        future_items << [l(:label_next_month), 'next_month'] if options[:show_future] || eqeoc(:next_month, field, options)
        future_items << [l(:label_next_n_days, :days => 30), 'next_30_days'] if options[:show_future] || eqeoc(:next_30_days, field, options)
        future_items << [l(:label_next_n_days, :days => 90), 'next_90_days'] if options[:show_future] || eqeoc(:next_90_days, field, options)
        future_items << [l(:label_next_year), 'next_year'] if options[:show_future] || eqeoc(:next_year, field, options)
        # extended stuff
        future_items << [l(:label_after_due_date), 'after_due_date'] if eqeoc(:after_due_date, field, options)
      end

      fiscal_items = [
        [l(:label_last_fiscal_year), 'last_fiscal_year'],
        [l(:label_this_fiscal_year), 'current_fiscal_year'],
        [l(:label_next_fiscal_year), 'next_fiscal_year']
      ]

      custom_items = [
        [l(:label_in_less_than), 'in_less_than_n_days'],
        [l(:label_in_more_than), 'in_more_than_n_days'],
        [l(:label_in_next_days), 'in_next_n_days'],
        [l(:label_in), 'in_n_days'],

        [l(:label_less_than_ago), 'less_than_ago_n_days'],
        [l(:label_more_than_ago), 'more_than_ago_n_days'],
        [l(:label_in_past_days), 'in_past_n_days'],
        [l(:label_ago), 'ago_n_days']
      ]

      call_hook(:application_helper_options_for_period_select_bottom, {:past_items => past_items, :present_items => present_items, :future_items => future_items, :field => field, :options => options})

      r = Array.new
      r << [nil, no_category]
      r << [l(:label_period_past), past_items]
      r << [l(:label_period_present), present_items]
      r << [l(:label_period_future), future_items] if future_items.any?
      r << [l(:label_period_fiscal), fiscal_items]
      r << [l(:label_period_custom), custom_items]

      return grouped_options_for_select(r, value)
    end

  end
end
