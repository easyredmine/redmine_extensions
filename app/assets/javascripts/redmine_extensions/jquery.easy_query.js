(function( $, undefined ) {
  $.widget('easy.easy_query_edit', {
    options: {
      modul_uniq_id: null
    },

    _create: function() {
      var that = this;

      this.modul_uniq_id = this.options.modul_uniq_id || this.element.attr('id') || '';
      this.filters_container = $('.filters-table', this.element);

      $('.add_filter_select', this.element).change(function(evt){
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
    }
  });

})(jQuery);
