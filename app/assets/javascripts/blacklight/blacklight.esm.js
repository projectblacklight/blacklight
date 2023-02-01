const Blacklight = function() {
  const buffer = new Array;
  return {
    onLoad: function(func) {
      buffer.push(func);
    },

    activate: function() {
      for(let i = 0; i < buffer.length; i++) {
        buffer[i].call();
      }
    },

    listeners: function () {
      const listeners = [];
      if (typeof Turbo !== 'undefined') {
        listeners.push('turbo:load', 'turbo:frame-load');
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
  }

  async clicked(evt) {
    this.spanTarget.innerHTML = this.form.getAttribute('data-inprogress');
    this.labelTarget.setAttribute('disabled', 'disabled');
    this.checkboxTarget.setAttribute('disabled', 'disabled');
    const response = await fetch(this.formTarget.getAttribute('action'), {
      body: new FormData(this.formTarget),
      method: this.formTarget.getAttribute('method').toUpperCase(),
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': document.querySelector('meta[name=csrf-token]')?.content
      }
    });
    this.labelTarget.removeAttribute('disabled');
    this.checkboxTarget.removeAttribute('disabled');
    if (response.ok) {
      const json = await response.json();
      this.updateStateFor(!this.checked);
      document.querySelector('[data-role=bookmark-counter]').innerHTML = json.bookmarks.count;
    } else {
      alert('Error');
    }
  }

  get checked() {
    return (this.form.querySelectorAll('input[name=_method][value=delete]').length != 0)
  }

  get formTarget() {
    return this.form
  }

  get labelTarget() {
    return this.form.querySelector('[data-checkboxsubmit-target="label"]')
  }

  get checkboxTarget() {
    return this.form.querySelector('[data-checkboxsubmit-target="checkbox"]')
  }

  get spanTarget() {
    return this.form.querySelector('[data-checkboxsubmit-target="span"]')
  }

  updateStateFor(state) {
    this.checkboxTarget.checked = state;

    if (state) {
      this.labelTarget.classList.add('checked');
      //Set the Rails hidden field that fakes an HTTP verb
      //properly for current state action.
      this.formTarget.querySelector('input[name=_method]').value = 'delete';
      this.spanTarget.innerHTML = this.form.getAttribute('data-present');
    } else {
      this.labelTarget.classList.remove('checked');
      this.formTarget.querySelector('input[name=_method]').value = 'put';
      this.spanTarget.innerHTML = this.form.getAttribute('data-absent');
    }
  }
}

const BookmarkToggle = (() => {
    // change form submit toggle to checkbox
    Blacklight.doBookmarkToggleBehavior = function() {
      document.addEventListener('click', (e) => {
        if (e.target.matches('[data-checkboxsubmit-target="checkbox"]')) {
          const form = e.target.closest('form');
          if (form) new CheckboxSubmit(form).clicked(e);
        }
      });
    };
    Blacklight.doBookmarkToggleBehavior.selector = 'form.bookmark-toggle';

    Blacklight.doBookmarkToggleBehavior();
})();

const ButtonFocus = (() => {
  document.addEventListener('click', (e) => {
    // Button clicks should change focus. As of 10/3/19, Firefox for Mac and
    // Safari both do not set focus to a button on button click.
    // See https://zellwk.com/blog/inconsistent-button-behavior/ for background information
    if (e.target.matches('[data-toggle="collapse"]') || e.target.matches('[data-bs-toggle="collapse"]')) {
      e.target.focus();
    }
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

  Link or forms inside the modal will ordinarily cause page loads
  when they are triggered. However, if you'd like their results
  to stay within the modal, just add `data-blacklight-modal="preserve"`
  to the link or form.

  Here's an example of what might be returned, demonstrating most of the devices available:

    <div data-blacklight-modal="container">
      <div class="modal-header">
        <button type="button" class="close" data-bl-dismiss="modal" aria-hidden="true">×</button>
        <h3 class="modal-title">Request Placed</h3>
      </div>

      <div class="modal-body">
        <p>Some message</p>
        <%= link_to "This result will still be within modal", some_link, data: { blacklight_modal: "preserve" } %>
      </div>


      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bl-dismiss="modal">Close</button>
      </div>
    </div>


  One additional feature. If the content returned from the AJAX form submission
  can be a turbo-stream that defines some HTML fragementsand where on the page to put them:
  https://turbo.hotwired.dev/handbook/streams
*/

const Modal = (() => {
  // We keep all our data in Blacklight.modal object.
  // Create lazily if someone else created first.
  if (Blacklight.modal === undefined) {
    Blacklight.modal = {};
  }

  const modal = Blacklight.modal;

  // a Bootstrap modal div that should be already on the page hidden
  modal.modalSelector = '#blacklight-modal';

  // Trigger selectors identify forms or hyperlinks that should open
  // inside a modal dialog.
  modal.triggerLinkSelector  = 'a[data-blacklight-modal~=trigger]';

  // preserve selectors identify forms or hyperlinks that, if activated already
  // inside a modal dialog, should have destinations remain inside the modal -- but
  // won't trigger a modal if not already in one.
  //
  // No need to repeat selectors from trigger selectors, those will already
  // be preserved. MUST be manually prefixed with the modal selector,
  // so they only apply to things inside a modal.
  modal.preserveLinkSelector = modal.modalSelector + ' a[data-blacklight-modal~=preserve]';

  modal.containerSelector    = '[data-blacklight-modal~=container]';

  // Called on fatal failure of ajax load, function returns content
  // to show to user in modal.  Right now called only for network errors.
  modal.onFailure = function (error) {
      console.error('Server error:', this.url, error);

      const contents = `<div class="modal-header">
        <div class="modal-title">There was a problem with your request.</div>
        <button type="button" class="blacklight-modal-close btn-close close" data-bl-dismiss="modal" aria-label="Close">
          <span aria-hidden="true" class="visually-hidden">&times;</span>
        </button>
        </div>
        <div class="modal-body">
          <p>Expected a successful response from the server, but got an error</p>
          <pre>${this.url}\n${error}</pre>
        </div>`;

      document.querySelector(`${modal.modalSelector} .modal-content`).innerHTML = contents;

      modal.show();
  };

  // Add the passed in contents to the modal and display it.
  modal.receiveAjax = function (contents) {
      const domparser = new DOMParser();
      const dom = domparser.parseFromString(contents, "text/html");
      // If there is a containerSelector on the document, use its children.
      let elements = dom.querySelectorAll(`${modal.containerSelector} > *`);
      if (elements.length == 0) {
        // If the containerSelector wasn't found, use the whole document
        elements = dom.body.childNodes;
      }

      document.querySelector(`${modal.modalSelector} .modal-content`).replaceChildren(...elements);

      modal.show();
  };


  modal.modalAjaxLinkClick = function(e) {
    e.preventDefault();
    const href = e.target.getAttribute('href');
    fetch(href)
      .then(response => {
         if (!response.ok) {
           throw new TypeError("Request failed");
         }
         return response.text();
       })
      .then(data => modal.receiveAjax(data))
      .catch(error => modal.onFailure(error));
  };

  modal.setupModal = function() {
    // Register both trigger and preserve selectors in ONE event handler, combining
    // into one selector with a comma, so if something matches BOTH selectors, it
    // still only gets the event handler called once.
    document.addEventListener('click', (e) => {
      if (e.target.matches(`${modal.triggerLinkSelector}, ${modal.preserveLinkSelector}`))
        modal.modalAjaxLinkClick(e);
      else if (e.target.matches('[data-bl-dismiss="modal"]'))
        modal.hide();
    });
  };

  modal.hide = function (el) {
    const dom = document.querySelector(Blacklight.modal.modalSelector);

    if (!dom.open) return
    dom.close();
  };

  modal.show = function(el) {
    const dom = document.querySelector(Blacklight.modal.modalSelector);

    if (dom.open) return
    dom.showModal();
  };

  modal.setupModal();
})();

const SearchContext = (() => {
  Blacklight.doSearchContextBehavior = function() {
    document.addEventListener('click', (e) => {
      if (e.target.matches('[data-context-href]')) {
        Blacklight.handleSearchContextMethod.call(e.target, e);
      }
    });
  };

  Blacklight.csrfToken = () => document.querySelector('meta[name=csrf-token]')?.content;
  Blacklight.csrfParam = () => document.querySelector('meta[name=csrf-param]')?.content;

  // this is the Rails.handleMethod with a couple adjustments, described inline:
  // first, we're attaching this directly to the event handler, so we can check for meta-keys
  Blacklight.handleSearchContextMethod = function(event) {
    const link = this;

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
  };

  Blacklight.doSearchContextBehavior();
})();

const index = {
  BookmarkToggle,
  ButtonFocus,
  Modal,
  SearchContext,
  Core: Blacklight,
  onLoad: Blacklight.onLoad
};

export { index as default };
//# sourceMappingURL=blacklight.esm.js.map
