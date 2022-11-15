import { Controller } from '@hotwired/stimulus';

class BookmarkToggle extends Controller {
  static targets = ['label', 'checkbox']
  static values = {
    present: String,
    absent: String,
    inprogress: String,
    url: String
  }

  async toggle() {
    this.labelTarget.innerHTML = this.inprogressValue;
    this.labelTarget.setAttribute('disabled', 'disabled');
    this.element.setAttribute('disabled', 'disabled');
    const id = this.element.id;
    const response = await fetch(this.urlValue, {
      body: { id: id },
      method: this.checkboxTarget.checked ? 'PUT' : 'DELETE',
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': document.querySelector('meta[name=csrf-token]')?.content
      }
    });
    this.labelTarget.removeAttribute('disabled');
    this.element.removeAttribute('disabled');
    if (response.ok) {
      const json = await response.json();
      this.checked = !this.checked;
      this.labelTarget.innerHTML = this.checked ? this.presentValue : this.absentValue;

      document.querySelector('[data-role=bookmark-counter]').innerHTML = json.bookmarks.count;
    } else {
      alert('There was a problem bookmarking this document');
    }
  }
}

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
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
        <h3 class="modal-title">Request Placed</h3>
      </div>

      <div class="modal-body">
        <p>Some message</p>
        <%= link_to "This result will still be within modal", some_link, data: { blacklight_modal: "preserve" } %>
      </div>


      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
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
  // to show to user in modal.  Right now called only for extreme
  // network errors.
  modal.onFailure = function (jqXHR, textStatus, errorThrown) {
      console.error('Server error:', this.url, jqXHR.status, errorThrown);

      const contents = `<div class="modal-header">
        <div class="modal-title">There was a problem with your request.</div>
        <button type="button" class="blacklight-modal-close btn-close close" data-dismiss="modal" data-bs-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
        </div>
        <div class="modal-body">
          <p>Expected a successful response from the server, but got an error</p>
          <pre>${this.type} ${this.url}\n${jqXHR.status}: ${errorThrown}</pre>
        </div>`;

      document.querySelector(`${modal.modalSelector} .modal-content`).innerHTML = contents;

      modal.show();
  };

  // Add the passed in contents to the modal and display it.
modal.receiveAjax = function (contents) {
      const domparser = new DOMParser();
      const dom = domparser.parseFromString(contents, "text/html");
      const elements = dom.querySelectorAll(`${modal.containerSelector} > *`);
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

  Blacklight.onLoad(function() {
    modal.setupModal();
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
    event.stopPropagation();
  };

  Blacklight.onLoad(function() {
    Blacklight.doSearchContextBehavior();
  });
})();

Stimulus.register('blacklight-bookmark', BookmarkToggle);

const index = {
  BookmarkToggle,
  ButtonFocus,
  Modal,
  SearchContext,
  onLoad: Blacklight.onLoad
};

export { index as default };
//# sourceMappingURL=blacklight.esm.js.map
