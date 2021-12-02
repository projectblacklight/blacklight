(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory(require('typeahead.js/dist/bloodhound.js')) :
  typeof define === 'function' && define.amd ? define(['typeahead.js/dist/bloodhound.js'], factory) :
  (global = typeof globalThis !== 'undefined' ? globalThis : global || self, global.Blacklight = factory(global.Bloodhound));
})(this, (function (Bloodhound) { 'use strict';

  const _interopDefaultLegacy = e => e && typeof e === 'object' && 'default' in e ? e : { default: e };

  const Bloodhound__default = /*#__PURE__*/_interopDefaultLegacy(Bloodhound);

  const Blacklight = function() {
    var buffer = new Array;
    return {
      onLoad: function(func) {
        buffer.push(func);
      },

      activate: function() {
        for(var i = 0; i < buffer.length; i++) {
          buffer[i].call();
        }
      },

      listeners: function () {
        var listeners = [];
        if (typeof Turbo !== 'undefined') {
          listeners.push('turbo:load');
        } else if (typeof Turbolinks !== 'undefined' && Turbolinks.supported) {
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
  Blacklight.listeners().forEach(function(listener) {
    document.addEventListener(listener, function() {
      Blacklight.activate();
    });
  });

  Blacklight.onLoad(function () {
    const elem = document.querySelector('.no-js');

    // The "no-js" class may already have been removed because this function is
    // run on every turbo:load event, in that case, it won't find an element.
    if (!elem) return;

    elem.classList.remove('no-js');
    elem.classList.add('js');
  });

  const Autocomplete = (() => {
    Blacklight.onLoad(function() {

      $('[data-autocomplete-enabled="true"]').each(function() {
        var $el = $(this);
        if($el.hasClass('tt-hint')) {
          return;
        }
        var suggestUrl = $el.data().autocompletePath;

        var terms = new Bloodhound__default.default({
          datumTokenizer: Bloodhound__default.default.tokenizers.obj.whitespace('value'),
          queryTokenizer: Bloodhound__default.default.tokenizers.whitespace,
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
        },
        {
          name: 'terms',
          displayKey: 'term',
          source: terms.ttAdapter()
        });
      });
    });
  })();

  /* Converts a "toggle" form, with single submit button to add/remove
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
    Uses HTML for a checkbox compatible with Bootstrap 4.
     new CheckboxSubmit(document.querySelector('form.something')).render()
  */
  class CheckboxSubmit {
    constructor(form) {
      this.form = form;
      this.cssClass = 'toggle-bookmark';

      //View needs to set data-doc-id so we know a unique value
      //for making DOM id
      const uniqueId = this.form.getAttribute('data-doc-id') || Math.random();
      const id = `${this.cssClass}_${uniqueId}`;
      this.checkbox = this._buildCheckbox(this.cssClass, id);
      this.span = this._buildSpan();
      this.label = this._buildLabel(id, this.cssClass, this.checkbox, this.span);

      // if form is currently using method delete to change state,
      // then checkbox is currently checked
      this.checked = (this.form.querySelectorAll('input[name=_method][value=delete]').length != 0);
    }

    _buildCheckbox(cssClass, id) {
      const checkbox = document.createElement('input');
      checkbox.setAttribute('type', 'checkbox');
      checkbox.classList.add(cssClass);
      checkbox.id = id;
      return checkbox
    }

    _buildLabel(id, cssClass, checkbox, span) {
      const label = document.createElement('label');
      label.classList.add(cssClass);
      label.for = id;

      label.appendChild(checkbox);
      label.appendChild(document.createTextNode(' '));
      label.appendChild(span);
      return label
    }

    _buildSpan() {
      return document.createElement('span')
    }

    _buildCheckboxDiv() {
      const checkboxDiv = document.createElement('div');
      checkboxDiv.classList.add('checkbox');
      checkboxDiv.classList.add(this.cssClass);
      checkboxDiv.appendChild(this.label);
      return checkboxDiv
    }

    render() {
      const children = this.form.children;
      Array.from(children).forEach((child) => child.classList.add('hidden'));

      //We're going to use the existing form to actually send our add/removes
      //This works conveneintly because the exact same action href is used
      //for both bookmarks/$doc_id.  But let's take out the irrelevant parts
      //of the form to avoid any future confusion.
      this.form.querySelectorAll('input[type=submit]').forEach((el) => this.form.removeChild(el));
      this.form.appendChild(this._buildCheckboxDiv());
      this.updateStateFor(this.checked);

      this.checkbox.onclick = this._clicked.bind(this);
    }

    async _clicked(evt) {
      this.span.innerHTML = this.form.getAttribute('data-inprogress');
      this.label.setAttribute('disabled', 'disabled');
      this.checkbox.setAttribute('disabled', 'disabled');
      const response = await fetch(this.form.getAttribute('action'), {
        body: new FormData(this.form),
        method: this.form.getAttribute('method').toUpperCase(),
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      });
      this.label.removeAttribute('disabled');
      this.checkbox.removeAttribute('disabled');
      if (response.ok) {
        const json = await response.json();
        this.checked = !this.checked;
        this.updateStateFor(this.checked);
        document.querySelector('[data-role=bookmark-counter]').innerHTML = json.bookmarks.count;
      } else {
        alert('Error');
      }
    }

    updateStateFor(state) {
      this.checkbox.checked = state;

      if (state) {
        this.label.classList.add('checked');
        //Set the Rails hidden field that fakes an HTTP verb
        //properly for current state action.
        this.form.querySelector('input[name=_method]').value = 'delete';
        this.span.innerHTML = this.form.getAttribute('data-present');
      } else {
        this.label.classList.remove('checked');
        this.form.querySelector('input[name=_method]').value = 'put';
        this.span.innerHTML = this.form.getAttribute('data-absent');
      }
    }
  }

  const BookmarkToggle = (() => {
      // change form submit toggle to checkbox
      Blacklight.doBookmarkToggleBehavior = function() {
        document.querySelectorAll(Blacklight.doBookmarkToggleBehavior.selector).forEach((el) => {
          new CheckboxSubmit(el).render();
        });
      };
      Blacklight.doBookmarkToggleBehavior.selector = 'form.bookmark-toggle';

      Blacklight.onLoad(function() {
        Blacklight.doBookmarkToggleBehavior();
      });
  })();

  const ButtonFocus = (() => {
    Blacklight.onLoad(function() {
      // Button clicks should change focus. As of 10/3/19, Firefox for Mac and
      // Safari both do not set focus to a button on button click.
      // See https://zellwk.com/blog/inconsistent-button-behavior/ for background information
      document.querySelectorAll('button.collapse-toggle').forEach((button) => {
        button.addEventListener('click', () => {
          event.target.focus();
        });
      });
    });
  })();

  Blacklight.doResizeFacetLabelsAndCounts = function() {
    // adjust width of facet columns to fit their contents
    function longer (a,b) { return b.textContent.length - a.textContent.length }

    document.querySelectorAll('.facet-values, .pivot-facet').forEach(function(elem){
      const nodes = elem.querySelectorAll('.facet-count');
      // TODO: when we drop ie11 support, this can become the spread operator:
      const longest = Array.from(nodes).sort(longer)[0];
      if (longest && longest.textContent) {
        const width = longest.textContent.length + 1 + 'ch';
        elem.querySelector('.facet-count').style.width = width;
      }
    });
  };

  const FacetLoad = (() => {
    Blacklight.onLoad(function() {
      Blacklight.doResizeFacetLabelsAndCounts();
    });
  })();

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
          <%= link_to "This result will still be within modal", some_link, data: { blacklight_modal: "preserve" } %>
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

  const Modal = (() => {
    // We keep all our data in Blacklight.modal object.
    // Create lazily if someone else created first.
    if (Blacklight.modal === undefined) {
      Blacklight.modal = {};
    }

    // a Bootstrap modal div that should be already on the page hidden
    Blacklight.modal.modalSelector = '#blacklight-modal';

    // Trigger selectors identify forms or hyperlinks that should open
    // inside a modal dialog.
    Blacklight.modal.triggerLinkSelector  = 'a[data-blacklight-modal~=trigger]';
    Blacklight.modal.triggerFormSelector  = 'form[data-blacklight-modal~=trigger]';

    // preserve selectors identify forms or hyperlinks that, if activated already
    // inside a modal dialog, should have destinations remain inside the modal -- but
    // won't trigger a modal if not already in one.
    //
    // No need to repeat selectors from trigger selectors, those will already
    // be preserved. MUST be manually prefixed with the modal selector,
    // so they only apply to things inside a modal.
    Blacklight.modal.preserveLinkSelector = Blacklight.modal.modalSelector + ' a[data-blacklight-modal~=preserve]';

    Blacklight.modal.containerSelector    = '[data-blacklight-modal~=container]';

    Blacklight.modal.modalCloseSelector   = '[data-blacklight-modal~=close]';

    // Called on fatal failure of ajax load, function returns content
    // to show to user in modal.  Right now called only for extreme
    // network errors.
    Blacklight.modal.onFailure = function(jqXHR, textStatus, errorThrown) {
      console.error('Server error:', this.url, jqXHR.status, errorThrown);

      var contents = '<div class="modal-header">' +
                '<div class="modal-title">There was a problem with your request.</div>' +
                '<button type="button" class="blacklight-modal-close btn-close close" data-dismiss="modal" aria-label="Close">' +
                '  <span aria-hidden="true">&times;</span>' +
                '</button></div>' +
                ' <div class="modal-body"><p>Expected a successful response from the server, but got an error</p>' +
                '<pre>' +
                this.type + ' ' + this.url + "\n" + jqXHR.status + ': ' + errorThrown +
                '</pre></div>';
      $(Blacklight.modal.modalSelector).find('.modal-content').html(contents);
      Blacklight.modal.show();
    };

    Blacklight.modal.receiveAjax = function (contents) {
        // does it have a data- selector for container?
        // important we don't execute script tags, we shouldn't.
        // code modelled off of JQuery ajax.load. https://github.com/jquery/jquery/blob/main/src/ajax/load.js?source=c#L62
        var container =  $('<div>').
          append( jQuery.parseHTML(contents) ).find( Blacklight.modal.containerSelector ).first();
        if (container.length !== 0) {
          contents = container.html();
        }

        $(Blacklight.modal.modalSelector).find('.modal-content').html(contents);

        // send custom event with the modal dialog div as the target
        var e    = $.Event('loaded.blacklight.blacklight-modal');
        $(Blacklight.modal.modalSelector).trigger(e);
        // if they did preventDefault, don't show the dialog
        if (e.isDefaultPrevented()) return;

        Blacklight.modal.show();
    };


    Blacklight.modal.modalAjaxLinkClick = function(e) {
      e.preventDefault();

      fetch($(this).attr('href'))
        .then(response => {
           if (!response.ok) {
             throw new TypeError("Request failed");
           }
           return response.text();
         })
        .then(data => Blacklight.modal.receiveAjax(data))
        .catch(error => Blacklight.modal.onFailure(error));
    };

    Blacklight.modal.modalAjaxFormSubmit = function(e) {
        e.preventDefault();

        $.ajax({
          url: $(this).attr('action'),
          data: $(this).serialize(),
          type: $(this).attr('method') // POST
        })
        .fail(Blacklight.modal.onFailure)
        .done(Blacklight.modal.receiveAjax);
    };



    Blacklight.modal.setupModal = function() {
    	// Event indicating blacklight is setting up a modal link,
      // you can catch it and call e.preventDefault() to abort
      // setup.
    	var e = $.Event('setup.blacklight.blacklight-modal');
    	$('body').trigger(e);
    	if (e.isDefaultPrevented()) return;

      // Register both trigger and preserve selectors in ONE event handler, combining
      // into one selector with a comma, so if something matches BOTH selectors, it
      // still only gets the event handler called once.
      $('body').on('click', Blacklight.modal.triggerLinkSelector + ', ' + Blacklight.modal.preserveLinkSelector,
        Blacklight.modal.modalAjaxLinkClick);
      $('body').on('submit', Blacklight.modal.triggerFormSelector + ', ' + Blacklight.modal.preserveFormSelector,
        Blacklight.modal.modalAjaxFormSubmit);

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
    Blacklight.modal.checkCloseModal = function(event) {
      if ($(event.target).find(Blacklight.modal.modalCloseSelector).length) {
        var modalFlashes = $(this).find('.flash_messages');

        Blacklight.modal.hide(event.target);
        event.preventDefault();

        var mainFlashes = $('#main-flashes');
        mainFlashes.append(modalFlashes);
        modalFlashes.fadeIn(500);
      }
    };

    Blacklight.modal.hide = function(el) {
      if (bootstrap.Modal.VERSION >= "5") {
        bootstrap.Modal.getOrCreateInstance(el || document.querySelector(Blacklight.modal.modalSelector)).hide();
      } else {
        $(el || Blacklight.modal.modalSelector).modal('hide');
      }
    };

    Blacklight.modal.show = function(el) {
      if (bootstrap.Modal.VERSION >= "5") {
        bootstrap.Modal.getOrCreateInstance(el || document.querySelector(Blacklight.modal.modalSelector)).show();
      } else {
        $(el || Blacklight.modal.modalSelector).modal('show');
      }
    };

    Blacklight.onLoad(function() {
      Blacklight.modal.setupModal();
    });
  })();

  const SearchContext = (() => {
    Blacklight.doSearchContextBehavior = function() {
      const elements = document.querySelectorAll('a[data-context-href]');
      const nodes = Array.from(elements);

      nodes.forEach(function(element) {
        element.addEventListener('click', function(e) {
          Blacklight.handleSearchContextMethod.call(e.currentTarget, e);
        });
      });
    };

    Blacklight.csrfToken = () => document.querySelector('meta[name=csrf-token]')?.content;
    Blacklight.csrfParam = () => document.querySelector('meta[name=csrf-param]')?.content;

    // this is the Rails.handleMethod with a couple adjustments, described inline:
    // first, we're attaching this directly to the event handler, so we can check for meta-keys
    Blacklight.handleSearchContextMethod = function(event) {
      var link = this;

      // instead of using the normal href, we need to use the context href instead
      let href = link.getAttribute('data-context-href');
      let target = link.getAttribute('target');
      let csrfToken = Blacklight.csrfToken();
      let csrfParam = Blacklight.csrfParam();
      let form = document.createElement('form');
      form.method = 'post';
      form.action = href;


      let formContent = `<input name="_method" value="post" type="hidden" />
      <input name="redirect" value="${link.getAttribute('href')}" type="hidden" />`;

      // check for meta keys.. if set, we should open in a new tab
      if(event.metaKey || event.ctrlKey) {
        target = '_blank';
      }

      if (csrfParam !== undefined && csrfToken !== undefined) {
        formContent += `<input name="${csrfParam}" value="${csrfToken}" type="hidden" />`;
      }

      // Must trigger submit by click on a button, else "submit" event handler won't work!
      // https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/submit
      formContent += '<input type="submit" />';

      if (target) { form.setAttribute('target', target); }

      form.style.display = 'none';
      form.innerHTML = formContent;
      document.body.appendChild(form);
      form.querySelector('[type="submit"]').click();

      event.preventDefault();
      event.stopPropagation();
    };

    Blacklight.onLoad(function() {
      Blacklight.doSearchContextBehavior();
    });
  })();

  const index = {
    Autocomplete,
    BookmarkToggle,
    ButtonFocus,
    FacetLoad,
    Modal,
    SearchContext,
    onLoad: Blacklight.onLoad
  };

  return index;

}));
//# sourceMappingURL=blacklight.js.map
