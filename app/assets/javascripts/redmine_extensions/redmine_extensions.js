REDMINE_EXTENSIONS = {

  toggleDiv: function(el_or_id) {
    var el;
    if (typeof(el_or_id) === 'string') {
        el = $('#' + el_or_id);
    } else {
        el = el_or_id;
    }

    el.toggleClass('collapsed').slideToggle('fast');
  },

  toggleDivAndChangeOpen: function(toggleElementId, changeOpenElement) {
    REDMINE_EXTENSIONS.toggleDiv(toggleElementId);
    $(changeOpenElement).toggleClass('open');
  },

  toggleFilterButtons: function(elButtonsID, elFilter1ID, elFilter2ID)
  {
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

(function($, undefined) {

    var plugin = 'easygrouploader';
    var defaults = {
        next_button_cols: 1,
        load_opened: false,
        load_limit: 25,
        texts: {
            'next': 'Next',
        }
    };

    $.fn[plugin] = function(options, methodParams) {
        $.each($(this), function(idx) {
            var instance = $(this).data('plugin_' + plugin);
            if (!instance) {
                instance = new EasyGroupLoader(this, options);
                $(this).data('plugin_' + plugin, instance);
            } else if (typeof options === 'string') {
                switch (options) {
                    case 'load_groups':
                        if (instance.options.load_opened)
                            instance.load_all_groups();
                }
            }
        });
        return $(this);
    };


    function EasyGroupLoader(elem, options) {
        this.groupsContainer = $(elem);
        this.options = $.extend({}, defaults, options);
        this.loadUrl = options.loadUrl || elem.data('url');
        this.texts = this.options.texts;

        this.init();
    }

    EasyGroupLoader.prototype.init = function()
    {
        var self = this;
        this.groupsContainer.on('click', '.group .expander', function(evt) {
            var $row = $(this).closest('tr.group');
            var group = $row.data('group') || new Group(self, $row);

            if (!group.loaded) {
                if (!group.header.hasClass('group-loaded')) {
                  group.load();
                  group.toggle();
                }
            } else {
                group.toggle();
            }

        });
        if (this.options.load_opened)
            this.load_all_groups();
    };

    EasyGroupLoader.prototype.initInlineEdit = function()
    {
        $('.multieditable-container:not(.multieditable-initialized)', this.groupsContainer).each(function() {
            initInlineEditForContainer(this);
        });
        initProjectEdit();
        initEasyAutocomplete();
    };

    EasyGroupLoader.prototype.load_all_groups = function()
    {
        var group;
        var self = this;
        var groups_to_load = [];
        var entity_count = 0;
        $('.group', this.groupsContainer).not('.group-loaded').each(function() {
            group = $(this).data('group') || new Group(self, $(this));
            if (!group.loaded) {
                groups_to_load.push(group);
                entity_count += group.count;
            }
            if (entity_count >= self.options.load_limit) {
                self.load_groups(groups_to_load);
                entity_count = 0;
                groups_to_load = [];
            }
        });
        if (groups_to_load.length > 0) {
            this.load_groups(groups_to_load);
        }
    };

    EasyGroupLoader.prototype.load_groups = function(groups_to_load) {
        var self = this;
        var group_names = groups_to_load.map(function(group) {
            return group.group_name
        });
        var url = EPExtensions.setAttrToUrl(this.loadUrl, 'group_to_load', group_names);
        $.get(url, function(data, textStatus, request) {
            var parsed = typeof data == 'object' ? data : $.parseJSON(data);

            $.each(groups_to_load, function(idx, group) {
                group.parseData(parsed[group.group_name]);
                group.toggle();
            });
            self.initInlineEdit();
        });
    };

    function Group(loader, header)
    {
        this.loader = loader;
        this.header = header;
        this.header.data('group', this);
        this.group_name = this.header.data('group-name');
        this.load_url = EPExtensions.setAttrToUrl(this.loader.loadUrl, 'group_to_load', this.group_name);
        this.count = parseInt(this.header.data('entity-count'));
        this.pages = this.header.data('pages') || 1;
        this.loaded = this.header.hasClass('preloaded');
    }

    Group.prototype.toggle = function() {
        EPExtensions.issuesToggleRowGroup(this.header);
    };

    Group.prototype.load = function() {
        var $hrow = this.header;
        var self = this;

        if (!$hrow.hasClass('group-loaded')) {
            $hrow.addClass('group-loaded');
            $.get(this.load_url, function(data, textStatus, request) {
                self.parseData(data);
                self.loader.initInlineEdit();
            });
        }
    };

    Group.prototype.parseData = function(data) {
        var $hrow = this.header;

        this.rows = $(data);
        $hrow.after(this.rows);
        $hrow.data('group-page', 1);
        this.loaded = true;
        if (this.pages > 1) {
            this.createNextButton();
            // .find doesn't work on this set
            this.rows.filter("tr:last").after(this.next_button);
        }
    };

    Group.prototype.loadNext = function() {
        var $hrow = this.header;
        var page = $hrow.data('group-page') + 1;
        var url = EPExtensions.setAttrToUrl(this.load_url, 'page', page);
        var self = this;

        if (page <= this.pages) {
            $.get(url, function(data, textStatus, request) {
                self.next_button.before(data);

                self.loader.initInlineEdit();
                $hrow.data('group-page', page);
                if (self.pages == page) {
                    self.next_button.remove();
                }
            });
        }
    };

    Group.prototype.createNextButton = function() {
        this.next_link = $('<a>', {href: this.load_url, 'class': 'button'}).text(this.loader.texts['next']).append($("<i>", {"class": "icon-arrow"}));
        this.next_button = $('<tr/>', {'class': 'easy-next-button'}).html($('<td>', {colspan: this.loader.options.next_button_cols, "class": "text-center"}).html(this.next_link));

        var self = this;

        this.next_link.click(function(evt) {
            evt.preventDefault();
            self.loadNext();
        });
    }

})(jQuery);

window.cancelAnimFrame = ( function() {
    return window.cancelAnimationFrame              ||
        window.webkitCancelRequestAnimationFrame    ||
        window.mozCancelRequestAnimationFrame       ||
        window.oCancelRequestAnimationFrame         ||
        window.msCancelRequestAnimationFrame        ||
        clearTimeout
} )();

window.requestAnimFrame = (function(){
    return  window.requestAnimationFrame   ||
        window.webkitRequestAnimationFrame ||
        window.mozRequestAnimationFrame    ||
        window.oRequestAnimationFrame      ||
        window.msRequestAnimationFrame     ||
        function(callback){
            return window.setTimeout(callback, 1000 / 60);
        };
})();

window.showFlashMessage = (function(type, message, delay){
    var $content = $("#content");
    delay = typeof delay !== 'undefined' ?  delay : false;
    $content.find(".flash").remove();
    var element = document.createElement("div");
    element.className = 'fixed flash ' + type;
    element.style.position = 'fixed';
    element.style.zIndex = '10001';
    element.style.right = '5px';
    element.style.top = '5px';
    var close = document.createElement("a");
    close.className = 'icon-close';
    close.setAttribute("href", "javascript:void(0)");
    close.setAttribute("onclick", "closeFlashMessage($(this))");
    var msg = document.createTextNode(message);
    var span = document.createElement("span");
    span.appendChild(msg);
    element.appendChild(span);
    element.appendChild(close);
    $content.prepend(element);
    var $element = $(element);
    if(delay){
        setTimeout(function(){
            requestFrame(function(){
                closeFlashMessage($element);
            });
        }, delay);
    }
    return $element;
})();

window.closeFlashMessage = (function($element){
    $element.closest('.flash').fadeOut(500, function(){$element.remove()});
})();