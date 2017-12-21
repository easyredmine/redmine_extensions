REDMINE_EXTENSIONS = {

  toggleDiv: function (el_or_id) {
    var el;
    if (typeof(el_or_id) === 'string') {
      el = $('#' + el_or_id);
    } else {
      el = el_or_id;
    }

    el.toggleClass('collapsed').slideToggle('fast');
  },

  toggleDivAndChangeOpen: function (toggleElementId, changeOpenElement) {
    REDMINE_EXTENSIONS.toggleDiv(toggleElementId);
    $(changeOpenElement).toggleClass('open');
  },

  toggleFilterButtons: function (elButtonsID, elFilter1ID, elFilter2ID) {
    var elButtons = $('#' + elButtonsID);
    var elFilter1 = $('#' + elFilter1ID);
    var elFilter2 = $('#' + elFilter2ID);

    if (elFilter1.hasClass('collapsed') && elFilter2.hasClass('collapsed')) {
      elButtons.slideUp('slow');
    } else {
      elButtons.slideDown('slow');
    }
  }

};

window.showFlashMessage = (function (type, message, delay) {
  var $content = $("#content");
  $content.find(".flash").remove();
  var element = document.createElement("div");
  element.className = 'fixed flash ' + type;
  element.style.position = 'fixed';
  element.style.zIndex = '10001';
  element.style.right = '5px';
  element.style.top = '5px';
  element.setAttribute("onclick", "closeFlashMessage($(this))");
  var close = document.createElement("a");
  close.className = 'icon-close close-icon';
  close.setAttribute("href", "javascript:void(0)");
  close.style.float = 'right';
  close.style.marginLeft = '5px';
  // close.setAttribute("onclick", "closeFlashMessage($(this))");
  var span = document.createElement("span");
  span.innerHTML = message;
  element.appendChild(close);
  element.appendChild(span);
  $content.prepend(element);
  var $element = $(element);
  if (delay) {
    setTimeout(function () {
      window.requestAnimationFrame(function () {
        closeFlashMessage($element);
      });
    }, delay);
  }
  return $element;
});

window.closeFlashMessage = (function ($element) {
  $element.closest('.flash').fadeOut(500, function () {
    $element.remove();
  });
});

EasyGem.schedule.require(function () {
  $.widget('easy.easymultiselect', {
    options: {
      source: null,
      rootElement: null, // rootElement in the response from source
      selected: null,
      multiple: true, // multiple values can be selected
      preload: true, // load all possible values
      position: {collision: 'flip'},
      autofocus: false,
      combo: false,
      inputName: null, // defaults to element prop name
      render_item: function (ul, item) {
        return $("<li>")
            .data("item.autocomplete", item)
            .text(item.label)
            .appendTo(ul);
      },
      activate_on_input_click: true,
      load_immediately: false,
      show_toggle_button: true,
      select_first_value: true,
      autocomplete_options: {}
    },

    _create: function () {
      this.selectedValues = this.options.selected;
      this._createUI();
      this.expanded = false;
      this.valuesLoaded = false;
      this.afterLoaded = [];
      if (Array.isArray(this.options.source)) {
        this.options.preload = true;
        this._initData(this.options.source);
      } else if (this.options.preload && this.options.load_immediately) {
        this.load();
      } else if (this.selectedValues) {
        this.setValue(this.selectedValues);
      }
    },

    _createUI: function () {
      var that = this;
      this.element.wrap('<span class="easy-autocomplete-tag"></span>');
      this.tag = this.element.parent();
      this.inputName = this.options.inputName || this.element.prop('name');

      if (this.options.multiple) { // multiple values
        this.valueElement = $('<span></span>');
        this.tag.after(this.valueElement);

        if (this.options.show_toggle_button)
          this._createToggleButton();

        this.valueElement.entityArray({
          inputNames: this.inputName,
          afterRemove: function (entity) {
            that.element.trigger('change');
          }
        });
      } else { //single value
        this.valueElement = $('<input>', {type: 'hidden', name: this.inputName});
        this.element.after(this.valueElement);
      }

      this._createAutocomplete();
      if (!this.options.multiple) {
        this.element.css('margin-right', 0);
      }
    },

    _createToggleButton: function () {
      var that = this;
      this.link_ac_toggle = $('<a>').attr('class', 'icon icon-add clear-link');
      this.link_ac_toggle.click(function (evt) {
        var $elem = $(this);
        evt.preventDefault();
        that.load(function () {
          var select = $('<select>').prop('multiple', true).prop('size', 5).prop('name', that.inputName);
          var option;
          $.each(that.possibleValues, function (i, v) {
            option = $('<option>').prop('value', v.id).text(v.value);
            option.prop('selected', that.getValue().indexOf(v.id) > -1);
            select.append(option);
          });
          var $container = $elem.closest('.easy-multiselect-tag-container');
          $container.find(':input').prop('disabled', true);
          $container.children().hide();
          $container.append(select);
          that.valueElement = select;
          that.expanded = true;
        });
      });
      this.element.parent().addClass('input-append');
      this.element.after(this.link_ac_toggle);
    },

    _createAutocomplete: function () {
      var that = this;

      that.element.autocomplete($.extend({
        source: function (request, response) {
          if (that.options.preload) {
            that.load(function () {
              var matcher = new RegExp($.ui.autocomplete.escapeRegex(request.term), "i");
              response($.grep(that.possibleValues, function (val, i) {
                return (!request.term || matcher.test(val.value));
              }));
            }, function () {
              response();
            });
          } else { // asking server everytime
            if (typeof that.options.source === 'function') {
              that.options.source(function (json) {
                response(that.options.rootElement ? json[that.options.rootElement] : json);
              });
            } else {
              $.getJSON(that.options.source, {
                term: request.term
              }, function (json) {
                response(that.options.rootElement ? json[that.options.rootElement] : json);
              });
            }
          }
        },
        minLength: 0,
        select: function (event, ui) {
          that.selectValue(ui.item);
          return false;
        },
        change: function (event, ui) {
          if (!ui.item) {
            if (that.options.combo) {
              $(this).val(that.element.val());
              if (!that.options.multiple) {
                that.valueElement.val(that.element.val());
                that.valueElement.change();
              }
            } else {
              $(this).val('');
              if (!that.options.multiple) {
                that.valueElement.val('');
                that.valueElement.change();
              }
            }
          }
        },
        position: this.options.position,
        autoFocus: this.options.autofocus
      }, this.options.autocomplete_options)).data("ui-autocomplete")._renderItem = this.options.render_item;

      this.element.click(function () {
        $(this).select();
      });
      if (this.options.activate_on_input_click) {
        this.element.on('click', function () {
          if (!that.options.preload)
            that.element.focus().val('');
          that.element.trigger('keydown');
          that.element.autocomplete("search", that.element.val());
        });
      }

      $("<button type='button'>&nbsp;</button>")
          .attr("tabIndex", -1)
          .insertAfter(that.element)
          .button({
            icons: {
              primary: "ui-icon-triangle-1-s"
            },
            text: false
          })
          .removeClass("ui-corner-all")
          .addClass("ui-corner-right ui-button-icon")
          .css('font-size', '10px')
          .css('margin-left', -1)
          .click(function () {
            if (that.element.autocomplete("widget").is(":visible")) {
              that.element.autocomplete("close");
              that.element.blur();
              return;
            }
            $(this).blur();
            that.element.focus().val('');
            that.element.trigger('keydown');
            that.element.autocomplete("search", that.element.val());
          });
    },

    _formatData: function (data) {
      return $.map(data, function (elem, i) {
        var id, value;
        if (elem instanceof Array) {
          value = elem[0];
          id = elem[1];
        } else if (elem instanceof Object) {
          value = elem.value;
          id = elem.id;
        } else {
          id = value = elem;
        }
        return {value: value, id: id};
      });
    },

    _initData: function (data) {
      this.possibleValues = this._formatData(data);
      this.valuesLoaded = true;

      this.selectedValues = this.selectedValues ? this.selectedValues : [];
      if (this.selectedValues.length === 0 && this.options.preload && this.options.select_first_value && this.possibleValues.length > 0) {
        this.selectedValues.push(this.possibleValues[0]['id']);
      }

      this.setValue(this.selectedValues);
    },

    load: function (success, fail) {
      var that = this;
      if (this.valuesLoaded) {
        if (typeof success === 'function')
          success();
        return;
      }

      if (typeof success === 'function')
        this.afterLoaded.push(success);

      if (this.loading)
        return;

      this.loading = true;

      function successFce(json, status, xhr) {
        var data = that.options.rootElement ? json[that.options.rootElement] : json;
        if (!data && window.console) {
          console.warn('Data could not be loaded! Please check the datasource.');
          data = [];
        }
        that._initData(data);
        for (var i = that.afterLoaded.length - 1; i >= 0; i--) {
          that.afterLoaded[i].call(that);
        }
        that.loading = false;
      }

      if (typeof this.options.source === 'function') {
        this.options.source(successFce);
      } else {
        $.ajax(this.options.source, {
          dataType: 'json',
          success: successFce,
          error: fail
        }).always(function () {
          that.loading = false; //even if ajax fails
        });
      }
    },

    selectValue: function (value) {
      if (this.options.multiple) {
        this.valueElement.entityArray('add', {
          id: value.id,
          name: value.value
        });
        this.element.trigger('change');
        this.element.val('');
      } else {
        this.element.val(value.value);
        this.valueElement.val(value.id);
        this.valueElement.change();
        this.element.change();
      }
    },

    setValue: function (values) {
      var that = this;
      if (typeof values === 'undefined' || !values)
        return false;

      if (this.options.preload) {
        this.load(function () {
          if (that.options.multiple) {
            that.valueElement.entityArray('clear');
          }
          that._setValues(values);
        });
      } else {
        if (that.options.multiple) {
          that.valueElement.entityArray('clear');
        }
        that._setValues(values);
      }
    },

    _setValues: function (values) {
      var selected = [];

      if (values.length === 0)
        return false;

      // allows the combination of only id values and values with label
      for (var i = values.length - 1; i >= 0; i--) {
        if (values[i] instanceof Object && !Array.isArray(values[i]) && values[i] !== null) {
          selected.push(values[i]);
        } else if (this.options.preload) {
          var that = this;
          if (!Array.isArray(that.possibleValues))
            return;
          for (var j = that.possibleValues.length - 1; j >= 0; j--) {
            if (values[i] === that.possibleValues[j].id || values[i] === that.possibleValues[j].id.toString()) {
              selected.push(that.possibleValues[j]);
              break;
            }
          }
        } else {
          selected.push({id: values[i], value: values[i]});
        }
      }
      for (var i = selected.length - 1; i >= 0; i--) {
        if (this.options.multiple) {
          this.valueElement.entityArray('add', {id: selected[i].id, name: selected[i].value});
        } else {
          this.element.val(selected[i].value);
          this.valueElement.val(selected[i].id);
        }
      }
    },

    getValue: function (with_label) {
      var result;
      if (this.options.multiple && !this.expanded) {
        result = this.valueElement.entityArray('getValue'); // entityArray
      } else if (this.options.multiple) {
        result = this.valueElement.val(); // select multiple=true
      } else {
        result = [this.valueElement.val()]; // hidden field
      }
      if (with_label) {
        result = this.possibleValues.filter(function (el) {
          return result.indexOf(el.id) >= 0;
        });
      }
      return result;
    }

  });

}, 'jQueryUI');
