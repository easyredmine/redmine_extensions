(function( $, undefined ) {
  $.widget('easy.easy_query', {
    options: {
      modul_uniq_id: null
    },

    _create: function() {
      var that = this;

      this.modul_uniq_id = this.options.modul_uniq_id || this.element.attr('id') || '';
      this.filters_container = $('.filters-table', this.element);

      $(this.element).on('change', '.add_filter_select', function(evt){
          var select = $(this),
            field = select.val();

          $('[id="' + that.modul_uniq_id + 'tr_' + field + '"]').show();
          $('[id="' + that.modul_uniq_id + 'cb_' + field + '"]').prop('checked', true);
          that.toggleFilter(field);
          select[0].selectedIndex = 0;
          $("option[value='" + field + "']", select).prop('disabled', true);
      });

      $("input[name='query[visibility]']", this.element).change(function(){
        var roles_checked = $('.query_visibility_roles', that.element).is(':checked');
        var private_checked = $('.query_visibility_private', that.element).is(':checked');
        $("input[name='query[role_ids][]'][type=checkbox]").attr('disabled', !roles_checked);
        if (!private_checked) $("input.disable-unless-private", that.element).attr('checked', false);
        $("input.disable-unless-private").attr('disabled', !private_checked);
      }).trigger('change');

      /* filters showing and hiding evts */
      if(this.filters_container.length > 0) {
        $.each(this.filters_container.data('enabled'), function(){
          that.toggleFilter(this);
        });

        $(this.filters_container).on('change', '.filter_select_operator', function(evt) {
          that.toggleOperator( $(this).data('field') );
        });
        $(this.filters_container).on('change', '.filters_checkbox', function(evt) {
          that.toggleFilter( $(this).val() );
        });
      }

      /* QUERY APPLY */
      $('.filter_buttons .apply-link', this.element).click(function(evt){
        var $this = $(this);
        evt.preventDefault();
        that.applyEasyQueryFilters($this.attr('href'), $($this.data('toserialize')) );
      });
      $('.filter_buttons .save-link', this.element).click(function(evt){
        var query_form_id = '#'+that.modul_uniq_id+'query_form';
        evt.preventDefault();
        that.applyEasyQueryFilters($(query_form_id).attr('action'), $(query_form_id + ' .query-form-addtional-hidden-fields input:hidden'));
      });
    },

    toggleFilter: function(field) {
      var check_box = $('#' + this.modul_uniq_id + 'cb_' + field);

      if (check_box.is(':checked')) {
          $('#' + this.modul_uniq_id + "operators_" + field).show();
          this.toggleOperator(field, this.modul_uniq_id);
      } else {
          $('#' + this.modul_uniq_id + "operators_" + field).hide();
          $('#' + this.modul_uniq_id + "div_values_" + field).hide();
      }
    },


    toggleOperator: function(field) {
        var operator = $('#' + this.modul_uniq_id + "operators_" + field);
        if (typeof(operator.val()) === 'undefined') {
            $('#' + this.modul_uniq_id + "div_values_" + field).show();
        } else {
            switch (operator.val()) {
                case "!*":
                case "*":
                case "t":
                case "ld":
                case "w":
                case "lw":
                case "l2w":
                case "m":
                case "lm":
                case "y":
                case "o":
                case "c":
                    this.enableValues(field, []);
                    break;
                case "><":
                    this.enableValues(field, [0, 1]);
                    break;
                case "<t+":
                case ">t+":
                case "><t+":
                case "t+":
                case ">t-":
                case "<t-":
                case "><t-":
                case "t-":
                    this.enableValues(field, [2]);
                    break;
                case "=p":
                case "=!p":
                case "!p":
                    this.enableValues(field, [1]);
                    break;
                default:
                    this.enableValues(field, [0]);
                    break;
            }
        }
    },

    enableValues: function(field, indexes) {
        var div_values = $('#' + this.modul_uniq_id + "div_values_" + field);
        div_values.find(".values_" + field).each(function(i) {
            if (indexes.indexOf(i) > -1) {
                $(this).prop('disabled', false).parent('span').show();
            } else {
                $(this).prop('disabled', true).val('').parent('span').hide();
            }
        });
        div_values.toggle(indexes.length > 0);
    },

    getEasyQueryFilterValue: function(filter_value_element) {
        var filter_value = '',
                val_el_val = [];

        if (filter_value_element.length > 0) {
            if (filter_value_element[0].tagName === 'SPAN') {
                filter_value_element.find('input[type="hidden"]').each(function(i, el) {
                    val_el_val.push($(el).val());
                });
            } else if (filter_value_element[0].tagName === 'SELECT') {
                var value = filter_value_element.val();
                if ($.isArray(value)) {
                    $.merge(val_el_val, value)
                } else {
                    val_el_val.push(value);
                }
            } else if (filter_value_element.is("input:radio")) {
                val_el_val.push(filter_value_element.filter(":checked").val());
            } else {
                filter_value_element.each(function() {
                    val_el_val.push($(this).val());
                });
            }
            filter_value = val_el_val && val_el_val.join('|');
        }
        return filter_value;
    },

    getEasyQueryFiltersForURL: function() {
        var modul_uniq_id = this.modul_uniq_id,
          that = this,
          filter_values = [];

        $('#' + modul_uniq_id + 'filters table.filters-table input:checkbox[name*="fields"]').filter(":checked").each(function(idx, el) {
            var filter_value = '';
            var el_val = el.value.replace('.', '_');
            var operator = $('#' + modul_uniq_id + 'operators_' + el_val).val();
            var val_el_single_value = $("tr#" + modul_uniq_id + "tr_"+el_val).children('td:last').find("input:not(.ui-autocomplete-input), select");
            var val_el_two_values_1 = $('#' + modul_uniq_id + 'values_' + el_val + '_1');
            var val_el_two_values_2 = $('#' + modul_uniq_id + 'values_' + el_val + '_2');
            if (operator === undefined) { operator = '='; }

            if (['=', '!', 'o', 'c', '*', '!*', '~', '!~', '^~', '=p', '=!p', '!p'].indexOf(operator) >= 0 && val_el_single_value.length > 0) {
                filter_value = that.getEasyQueryFilterValue(val_el_single_value);
            } else if (['=', '>=', '<=', '><', '!*', '*'].indexOf(operator) >= 0 && val_el_two_values_1.length > 0 && val_el_two_values_2.length > 0) {
                filter_value = that.getEasyQueryFilterValue(val_el_two_values_1);
                filter_value += '|' + that.getEasyQueryFilterValue(val_el_two_values_2);
            } else if (operator === '') {
                var p1 = $('#' + modul_uniq_id + '' + el_val + '_date_period_1');
                if (p1 && p1.is(':checked')) {
                    filter_value = $('#' + modul_uniq_id + 'values_' + el_val + '_period').val();
                    if (filter_value.indexOf('n_days') !== -1) {
                        filter_value += '|' + $('#' + modul_uniq_id + 'values_' + el_val + '_period_days').val();
                    }
                }
                var p2 = $('#' + modul_uniq_id + '' + el_val + '_date_period_2');
                if (p2 && p2.is(':checked')) {
                    filter_value = $('#' + modul_uniq_id + '' + el_val + '_from').val();
                    filter_value += '|' + $('#' + modul_uniq_id + '' + el_val + '_to').val();
                }
            }

            if (!filter_value) { filter_value = '0'; }
            filter_values.push(el.value + '=' + encodeURIComponent(operator + filter_value));
        });
        this._selectAllOptions(modul_uniq_id + 'selected_columns');
        if ($('#selected_project_columns').length > 0)
            this._selectAllOptions(modul_uniq_id + 'selected_project_columns');
        filter_values.push($('#' + modul_uniq_id + 'selected_columns').serialize());
        var show_sum_val = $('#' + modul_uniq_id + 'show_sum_row_1').serialize();
        if (show_sum_val.length === 0) {
            show_sum_val = $('#' + modul_uniq_id + 'show_sum_row_0').serialize();
        }
        var options = $(':input', $((modul_uniq_id === '' ? '' : '#' + modul_uniq_id) + ' .easy_query_additional_options')).serialize();
        filter_values.push(show_sum_val);
        filter_values.push(options);
        filter_values.push($('#' + modul_uniq_id + 'group_by').serialize());
        filter_values.push($('select.serialize, input.serialize', $('#' + modul_uniq_id + 'filters').closest('form')).serialize());
        // TODO razeni
        return filter_values.join('&');
    },

    applyEasyQueryFilters: function(url, additional_elements_to_serialize) {
        if (url.indexOf('?') >= 0) {
            url += '&';
        } else {
            url += '?';
        }

        var target_url = url + this.getEasyQueryFiltersForURL();

        if (additional_elements_to_serialize && (additional_elements_to_serialize instanceof jQuery)) {
            target_url += '&' + additional_elements_to_serialize.serialize();
        }

        window.location = target_url;
    },

    _selectAllOptions: function(id)
    {
        var select = $('#'+id);
        select.children('option').prop('selected', true);
    }

  });

})(jQuery);
