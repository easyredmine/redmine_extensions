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

}
