Blacklight = function () {
  var buffer = new Array();
  return {
    onLoad: function (func) {
      buffer.push(func);
    },

    activate: function () {
      for (var i = 0; i < buffer.length; i++) {
        buffer[i].call();
      }
    },

    listeners: function () {
      var listeners = [];
      if (typeof Turbolinks !== 'undefined' && Turbolinks.supported) {
        // Turbolinks 5
        if (Turbolinks.BrowserAdapter) {
          listeners.push('turbolinks:load');
        } else {
          // Turbolinks < 5
          listeners.push('page:load', 'DOMContentLoaded');
        }
      } else {
        listeners.push('DOMContentLoaded');
      }

      return listeners;
    }
  };
}();

// turbolinks triggers page:load events on page transition
// If app isn't using turbolinks, this event will never be triggered, no prob.
Blacklight.listeners().forEach(function (listener) {
  document.addEventListener(listener, function () {
    Blacklight.activate();
  });
});

$('.no-js').removeClass('no-js').addClass('js');
/*global Bloodhound */

Blacklight.onLoad(function () {
  'use strict';

  $('[data-autocomplete-enabled="true"]').each(function () {
    var $el = $(this);
    if ($el.hasClass('tt-hint')) {
      return;
    }
    var suggestUrl = $el.data().autocompletePath;

    var terms = new Bloodhound({
      datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
      queryTokenizer: Bloodhound.tokenizers.whitespace,
      remote: {
        url: suggestUrl + '?q=%QUERY',
        wildcard: '%QUERY'
      }
    });

    terms.initialize();

    $el.typeahead({
      hint: true,
      highlight: true,
      minLength: 2
    }, {
      name: 'terms',
      displayKey: 'term',
      source: terms.ttAdapter()
    });
  });
});
(function ($) {
  //change form submit toggle to checkbox
  Blacklight.doBookmarkToggleBehavior = function () {
    if (typeof Blacklight.do_bookmark_toggle_behavior == 'function') {
      console.warn("do_bookmark_toggle_behavior is deprecated. Use doBookmarkToggleBehavior instead.");
      return Blacklight.do_bookmark_toggle_behavior();
    }
    $(Blacklight.doBookmarkToggleBehavior.selector).blCheckboxSubmit({
      // cssClass is added to elements added, plus used for id base
      cssClass: 'toggle-bookmark',
      success: function (checked, response) {
        if (response.bookmarks) {
          $('[data-role=bookmark-counter]').text(response.bookmarks.count);
        }
      }
    });
  };
  Blacklight.doBookmarkToggleBehavior.selector = 'form.bookmark-toggle';

  Blacklight.onLoad(function () {
    Blacklight.doBookmarkToggleBehavior();
  });
})(jQuery);
/* A JQuery plugin (should this be implemented as a widget instead? not sure)
   that will convert a "toggle" form, with single submit button to add/remove
   something, like used for Bookmarks, into an AJAXy checkbox instead.

   Apply to a form. Does require certain assumption about the form:
    1) The same form 'action' href must be used for both ADD and REMOVE
       actions, with the different being the hidden input name="_method"
       being set to "put" or "delete" -- that's the Rails method to pretend
       to be doing a certain HTTP verb. So same URL, PUT to add, DELETE
       to remove. This plugin assumes that.

       Plus, the form this is applied to should provide a data-doc-id
       attribute (HTML5-style doc-*) that contains the id/primary key
       of the object in question -- used by plugin for a unique value for
       DOM id's.

  Uses HTML for a checkbox compatible with Bootstrap 3.

   Pass in options for your class name and labels:
   $("form.something").blCheckboxSubmit({
        checked_label: "Selected",
        unchecked_label: "Select",
        progress_label: "Saving...",
        //cssClass is added to elements added, plus used for id base
        cssClass: "toggle_my_kinda_form",
        success: function(after_success_check_state) {
          #optional callback
        }
   });
*/
(function ($) {
  $.fn.blCheckboxSubmit = function (argOpts) {
    this.each(function () {
      var options = $.extend({}, $.fn.blCheckboxSubmit.defaults, argOpts);

      var form = $(this);
      form.children().hide();
      //We're going to use the existing form to actually send our add/removes
      //This works conveneintly because the exact same action href is used
      //for both bookmarks/$doc_id.  But let's take out the irrelevant parts
      //of the form to avoid any future confusion.
      form.find('input[type=submit]').remove();

      //View needs to set data-doc-id so we know a unique value
      //for making DOM id
      var uniqueId = form.attr('data-doc-id') || Math.random();
      // if form is currently using method delete to change state,
      // then checkbox is currently checked
      var checked = form.find('input[name=_method][value=delete]').size() != 0;

      var checkbox = $('<input type="checkbox">').addClass(options.cssClass).attr('id', options.cssClass + '_' + uniqueId);
      var label = $('<label>').addClass(options.cssClass).attr('for', options.cssClass + '_' + uniqueId).attr('title', form.attr('title') || '');
      var span = $('<span>');

      label.append(checkbox);
      label.append(' ');
      label.append(span);

      var checkboxDiv = $('<div class="checkbox" />').addClass(options.cssClass).append(label);

      function updateStateFor(state) {
        checkbox.prop('checked', state);
        label.toggleClass('checked', state);
        if (state) {
          //Set the Rails hidden field that fakes an HTTP verb
          //properly for current state action.
          form.find('input[name=_method]').val('delete');
          span.text(form.attr('data-present'));
        } else {
          form.find('input[name=_method]').val('put');
          span.text(form.attr('data-absent'));
        }
      }

      form.append(checkboxDiv);
      updateStateFor(checked);

      checkbox.click(function () {
        span.text(form.attr('data-inprogress'));
        label.attr('disabled', 'disabled');
        checkbox.attr('disabled', 'disabled');

        $.ajax({
          url: form.attr('action'),
          dataType: 'json',
          type: form.attr('method').toUpperCase(),
          data: form.serialize(),
          error: function () {
            alert('Error');
            updateStateFor(checked);
            label.removeAttr('disabled');
            checkbox.removeAttr('disabled');
          },
          success: function (data, status, xhr) {
            //if app isn't running at all, xhr annoyingly
            //reports success with status 0.
            if (xhr.status != 0) {
              checked = !checked;
              updateStateFor(checked);
              label.removeAttr('disabled');
              checkbox.removeAttr('disabled');
              options.success.call(form, checked, xhr.responseJSON);
            } else {
              alert('Error');
              updateStateFor(checked);
              label.removeAttr('disabled');
              checkbox.removeAttr('disabled');
            }
          }
        });

        return false;
      }); //checkbox.click

    }); //this.each
    return this;
  };

  $.fn.blCheckboxSubmit.defaults = {
    //cssClass is added to elements added, plus used for id base
    cssClass: 'blCheckboxSubmit',
    success: function () {} //callback
  };
})(jQuery);
(function ($) {
  Blacklight.onLoad(function () {
    // when clicking on a link that toggles the collapsing behavior, don't do anything
    // with the hash or the page could jump around.
    $(document).on('click', 'a[data-toggle=collapse][href="#"], [data-toggle=collapse] a[href="#"]', function (event) {
      event.preventDefault();
    });
  });
})(jQuery);
/*global Blacklight */

(function ($) {
  'use strict';

  Blacklight.doResizeFacetLabelsAndCounts = function () {
    // adjust width of facet columns to fit their contents
    function longer(a, b) {
      return b.textContent.length - a.textContent.length;
    }

    $('ul.facet-values, ul.pivot-facet').each(function () {
      var longest = $(this).find('span.facet-count').sort(longer)[0];

      if (longest && longest.textContent) {
        var width = longest.textContent.length + 1 + 'ch';
        $(this).find('.facet-count').first().width(width);
      }
    });
  };

  Blacklight.onLoad(function () {
    Blacklight.doResizeFacetLabelsAndCounts();
  });
})(jQuery);
//= require blacklight/core

/*
  The blacklight modal plugin can display some interactions inside a Bootstrap
  modal window, including some multi-page interactions.

  It supports unobtrusive Javascript, where a link or form that would have caused
  a new page load is changed to display it's results inside a modal dialog,
  by this plugin.  The plugin assumes there is a Bootstrap modal div
  on the page with id #blacklight-modal to use as the modal -- the standard Blacklight
  layout provides this.

  To make a link or form have their results display inside a modal, add
  `data-blacklight-modal="trigger"` to the link or form. (Note, form itself not submit input)
  With Rails link_to helper, you'd do that like:

      link_to something, link, data: { blacklight_modal: "trigger" }

  The results of the link href or form submit will be displayed inside
  a modal -- they should include the proper HTML markup for a bootstrap modal's
  contents. Also, you ordinarily won't want the Rails template with wrapping
  navigational elements to be used.  The Rails controller could suppress
  the layout when a JS AJAX request is detected, OR the response
  can include a `<div data-blacklight-modal="container">` -- only the contents
  of the container will be placed inside the modal, the rest of the
  page will be ignored.

  If you'd like to have a link or button that closes the modal,
  you can just add a `data-dismiss="modal"` to the link,
  standard Bootstrap convention. But you can also have
  an href on this link for non-JS contexts, we'll make sure
  inside the modal it closes the modal and the link is NOT followed.

  Link or forms inside the modal will ordinarily cause page loads
  when they are triggered. However, if you'd like their results
  to stay within the modal, just add `data-blacklight-modal="preserve"`
  to the link or form.

  Here's an example of what might be returned, demonstrating most of the devices available:

    <div data-blacklight-modal="container">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
        <h3 class="modal-title">Request Placed</h3>
      </div>

      <div class="modal-body">
        <p>Some message</p>
        <%= link_to "This result will still be within modal", some_link, data: { blacklight: "preserve" } %>
      </div>


      <div class="modal-footer">
        <%= link_to "Close the modal", request_done_path, class: "submit button dialog-close", data: { dismiss: "modal" } %>
      </div>
    </div>


  One additional feature. If the content returned from the AJAX modal load
  has an element with `data-blacklight-modal=close`, that will trigger the modal
  to be closed. And if this element includes a node with class "flash_messages",
  the flash-messages node will be added to the main page inside #main-flahses.

  == Events

  We'll send out an event 'loaded.blacklight.blacklight-modal' with the #blacklight-modal
  dialog as the target, right after content is loaded into the modal but before
  it is shown (if not already a shown modal).  In an event handler, you can
  inspect loaded content by looking inside $(this).  If you call event.preventDefault(),
  we won't 'show' the dialog (although it may already have been shown, you may want to
  $(this).modal("hide") if you want to ensure hidden/closed.

  The data-blacklight-modal=close behavior is implemented with this event, see for example.
*/

// We keep all our data in Blacklight.modal object.
// Create lazily if someone else created first.
if (Blacklight.modal === undefined) {
  Blacklight.modal = {};
}

// a Bootstrap modal div that should be already on the page hidden
Blacklight.modal.modalSelector = '#blacklight-modal';

// Trigger selectors identify forms or hyperlinks that should open
// inside a modal dialog.
Blacklight.modal.triggerLinkSelector = 'a[data-blacklight-modal~=trigger]';
Blacklight.modal.triggerFormSelector = 'form[data-blacklight-modal~=trigger]';

// preserve selectors identify forms or hyperlinks that, if activated already
// inside a modal dialog, should have destinations remain inside the modal -- but
// won't trigger a modal if not already in one.
//
// No need to repeat selectors from trigger selectors, those will already
// be preserved. MUST be manually prefixed with the modal selector,
// so they only apply to things inside a modal.
Blacklight.modal.preserveLinkSelector = Blacklight.modal.modalSelector + ' a[data-blacklight-modal~=preserve]';

Blacklight.modal.containerSelector = '[data-blacklight-modal~=container]';

Blacklight.modal.modalCloseSelector = '[data-blacklight-modal~=close]';

// Called on fatal failure of ajax load, function returns content
// to show to user in modal.  Right now called only for extreme
// network errors.
Blacklight.modal.onFailure = function (data) {
  var contents = '<div class="modal-header">' + '<div class="modal-title">Network Error</div>' + '<button type="button" class="blacklight-modal-close close" data-dismiss="modal" aria-label="Close">' + '  <span aria-hidden="true">&times;</span>' + '</button>';
  $(Blacklight.modal.modalSelector).find('.modal-content').html(contents);
  $(Blacklight.modal.modalSelector).modal('show');
};

Blacklight.modal.receiveAjax = function (contents) {
  // does it have a data- selector for container?
  // important we don't execute script tags, we shouldn't.
  // code modelled off of JQuery ajax.load. https://github.com/jquery/jquery/blob/master/src/ajax/load.js?source=c#L62
  var container = $('<div>').append(jQuery.parseHTML(contents)).find(Blacklight.modal.containerSelector).first();
  if (container.size() !== 0) {
    contents = container.html();
  }

  $(Blacklight.modal.modalSelector).find('.modal-content').html(contents);

  // send custom event with the modal dialog div as the target
  var e = $.Event('loaded.blacklight.blacklight-modal');
  $(Blacklight.modal.modalSelector).trigger(e);
  // if they did preventDefault, don't show the dialog
  if (e.isDefaultPrevented()) return;

  $(Blacklight.modal.modalSelector).modal('show');
};

Blacklight.modal.modalAjaxLinkClick = function (e) {
  e.preventDefault();

  $.ajax({
    url: $(this).attr('href')
  }).fail(Blacklight.modal.onFailure).done(Blacklight.modal.receiveAjax);
};

Blacklight.modal.modalAjaxFormSubmit = function (e) {
  e.preventDefault();

  $.ajax({
    url: $(this).attr('action'),
    data: $(this).serialize(),
    type: $(this).attr('method') // POST
  }).fail(Blacklight.modal.onFailure).done(Blacklight.modal.receiveAjax);
};

Blacklight.modal.setupModal = function () {
  // Event indicating blacklight is setting up a modal link,
  // you can catch it and call e.preventDefault() to abort
  // setup.
  var e = $.Event('setup.blacklight.blacklight-modal');
  $('body').trigger(e);
  if (e.isDefaultPrevented()) return;

  // Register both trigger and preserve selectors in ONE event handler, combining
  // into one selector with a comma, so if something matches BOTH selectors, it
  // still only gets the event handler called once.
  $('body').on('click', Blacklight.modal.triggerLinkSelector + ', ' + Blacklight.modal.preserveLinkSelector, Blacklight.modal.modalAjaxLinkClick);
  $('body').on('submit', Blacklight.modal.triggerFormSelector + ', ' + Blacklight.modal.preserveFormSelector, Blacklight.modal.modalAjaxFormSubmit);

  // Catch our own custom loaded event to implement data-blacklight-modal=closed
  $('body').on('loaded.blacklight.blacklight-modal', Blacklight.modal.checkCloseModal);

  // we support doing data-dismiss=modal on a <a> with a href for non-ajax
  // use, we need to suppress following the a's href that's there for
  // non-JS contexts.
  $('body').on('click', Blacklight.modal.modalSelector + ' a[data-dismiss~=modal]', function (e) {
    e.preventDefault();
  });
};

// A function used as an event handler on loaded.blacklight.blacklight-modal
// to catch contained data-blacklight-modal=closed directions
Blacklight.modal.checkCloseModal = function (event) {
  if ($(event.target).find(Blacklight.modal.modalCloseSelector).length) {
    var modalFlashes = $(this).find('.flash_messages');

    $(event.target).modal('hide');
    event.preventDefault();

    var mainFlashes = $('#main-flashes');
    mainFlashes.append(modalFlashes);
    modalFlashes.fadeIn(500);
  }
};

Blacklight.onLoad(function () {
  Blacklight.modal.setupModal();
});
//= require blacklight/core
(function ($) {
  Blacklight.doSearchContextBehavior = function () {
    if (typeof Blacklight.do_search_context_behavior == 'function') {
      console.warn("do_search_context_behavior is deprecated. Use doSearchContextBehavior instead.");
      return Blacklight.do_search_context_behavior();
    }
    $('a[data-context-href]').on('click.search-context', Blacklight.handleSearchContextMethod);
  };

  // this is the $.rails.handleMethod with a couple adjustments, described inline:
  // first, we're attaching this directly to the event handler, so we can check for meta-keys
  Blacklight.handleSearchContextMethod = function (event) {
    if (typeof Blacklight.handle_search_context_method == 'function') {
      console.warn("handle_search_context_method is deprecated. Use handleSearchContextMethod instead.");
      return Blacklight.handle_search_context_method(event);
    }
    var link = $(this);

    // instead of using the normal href, we need to use the context href instead
    var href = link.data('context-href'),
        method = 'post',
        target = link.attr('target'),
        csrfToken = $('meta[name=csrf-token]').attr('content'),
        csrfParam = $('meta[name=csrf-param]').attr('content'),
        form = $('<form method="post" action="' + href + '"></form>'),
        metadataInput = '<input name="_method" value="' + method + '" type="hidden" />',
        redirectHref = '<input name="redirect" value="' + link.attr('href') + '" type="hidden" />';

    // check for meta keys.. if set, we should open in a new tab
    if (event.metaKey || event.ctrlKey) {
      target = '_blank';
    }

    if (csrfParam !== undefined && csrfToken !== undefined) {
      metadataInput += '<input name="' + csrfParam + '" value="' + csrfToken + '" type="hidden" />';
    }

    if (target) {
      form.attr('target', target);
    }

    form.hide().append(metadataInput).append(redirectHref).appendTo('body');
    form.submit();

    return false;
  };

  Blacklight.onLoad(function () {
    Blacklight.doSearchContextBehavior();
  });
})(jQuery);

