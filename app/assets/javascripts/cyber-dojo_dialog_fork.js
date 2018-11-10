/*global jQuery,cyberDojo*/
'use strict';
var cyberDojo = ((cd, $) => {

  cd.forkDialog = (kata_id, index) => {
    const html = $('<div>', {
        id: 'fork-dialog',
      text: 'what kind of practice-session do you want to create?'
    });
    html.append($('<button>', {
         id: 'individual',
       type: 'button',
       text: 'individual'
    }).click(() => fork(kata_id, index, 'individual', 'edit')));
    html.append($('<button>', {
         id: 'group',
       type: 'button',
       text: 'group'
    }).click(() => fork(kata_id, index, 'group', 'group')));

    $(html).dialog({
      title: cd.dialogTitle('fork'),
      autoOpen: true,
      modal: true,
      width: 350,
      closeOnEscape: true,
      buttons: {
        'close': function() {
          $(this).remove();
        }
      }
    });
  };

  const fork = (kata_id, index, routeFrom, routeTo) => {
    $.ajax({
             url: `/forker/fork_${routeFrom}`,
            data: { id:kata_id, index:index },
        dataType: 'json',
           async: false,
         success: (response) => {
          if (response.forked) {
            window.open(`/kata/${routeTo}/${response.id}`);
          } else {
            //TODO:...
            alert(`individual-fork:failed :${response.reason}:`);
          }
        }
    });
  };

  /*
  const forkFailedDialog = (data, tag) => {
    const message =
      'Could not setup a new session from ' + ' ' + tag + '.' + '<br/>' +
      data.reason + ' does not exist.';
    $('<div>')
      .html(message)
      .dialog({
                title: cd.dialogTitle('fork failed'),
             autoOpen: true,
        closeOnEscape: true,
                modal: true,
                width: 450,
              buttons: { ok: function() { $(this).remove(); } }
      });
  };
  */

  return cd;

})(cyberDojo || {}, jQuery);
