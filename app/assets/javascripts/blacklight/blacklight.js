(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
  typeof define === 'function' && define.amd ? define(factory) :
  (global = typeof globalThis !== 'undefined' ? globalThis : global || self, global.Blacklight = factory());
})(this, (function () { 'use strict';

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

    modal.setupModal();
  })();

  const SearchContext = (() => {
    Blacklight.doSearchContextBehavior = function() {
      // intercept clicks on search results to use search context behavior
      document.addEventListener('click', (e) => {
        if (e.target.matches('[data-context-href]')) {
          Blacklight.handleSearchContextMethod.call(e.target, e);
        }
      });
      // page-links dynamic content depends on a loaded document
      Blacklight.onLoad(() => {
        // if page-links container has a data URL, do client-side search context behaviors
        const clientPageLinks = document.querySelectorAll('.page-links[data-page-links-url]');
        if (clientPageLinks[0]) {
          const storedSearch = new URLSearchParams(sessionStorage.getItem("blacklightSearch") || "");
          Blacklight.clientAppliedParams(storedSearch);
          Blacklight.clientPageLinks(clientPageLinks[0].getAttribute('data-page-links-url'), storedSearch);
        }
      });
    };

    Blacklight.csrfToken = () => document.querySelector('meta[name=csrf-token]')?.content;
    Blacklight.csrfParam = () => document.querySelector('meta[name=csrf-param]')?.content;
    Blacklight.searchStorage = () => document.querySelector('meta[name=blacklight-search-storage]')?.content;

    /**
     * for a URL, iterate over searchParams and return a hidden form input for each pair
     * @param {URL} searchUrl
     * @returns {string} input element source
     */
     const buildInputsFromSearchParams = function(searchUrl) {
      let inputs = '';
      for (const [paramName, paramValue] of searchUrl.searchParams.entries()) {
        inputs += `<input name="${paramName}" value="${paramValue}" type="hidden" />`;
      }
      return inputs
    };

    /**
     * build a submittable form to use in the onClick handler of a search result
     * @param {string} formAction
     * @param {?string} formTarget
     * @param {string} formMethod
     * @param {?string} redirectHref
     */
    const buildSearchContextResultForm = function(formAction, formTarget, formMethod, redirectHref) {
      let actionUrl = new URL(formAction, window.location);
      let csrfToken = Blacklight.csrfToken();
      let csrfParam = Blacklight.csrfParam();
      let form = document.createElement('form');
      form.action = actionUrl.pathname;
      form.method = (formMethod == 'get') ? formMethod : 'post';

      // check for meta keys.. if set, we should open in a new tab
      const target = (event.metaKey || event.ctrlKey) ? '_blank' : formTarget;
      if (target) form.target = target;

      form.hidden = true;

      let formContent = buildInputsFromSearchParams(actionUrl);
      if (formMethod != 'get' && formMethod != 'post') formContent += `<input name="_method" value="${formMethod}" type="hidden" />`;

      if (redirectHref) {
        formContent += `<input name="redirect" value="${redirectHref}" type="hidden" />`;
        if (csrfParam !== undefined && csrfToken !== undefined) {
          formContent += `<input name="${csrfParam}" value="${csrfToken}" type="hidden" />`;
        }
      }

      // Must trigger submit by click on a button, else "submit" event handler won't work!
      // https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/submit
      formContent += '<input type="submit" />';

      form.innerHTML = formContent;
      return form;
    };

    // this is the Rails.handleMethod with a couple adjustments, described inline:
    // first, we're attaching this directly to the event handler, so we can check for meta-keys
    Blacklight.handleSearchContextMethod = function(event) {
      const link = this;
      const clientSearchStorage = Blacklight.searchStorage() == 'client';
      if (clientSearchStorage) sessionStorage.setItem("blacklightSearch", new URLSearchParams(new URL(window.location).search));
      // instead of using the normal href, we need to use the context href instead
      const contextHref = new URL(link.getAttribute('data-context-href'), window.location);
      const linkTarget = link.getAttribute('target');
      const contextMethod = link.getAttribute('data-context-method') || 'post';
      const redirectHref = (clientSearchStorage) ? null : link.getAttribute('href');
      const form = buildSearchContextResultForm(contextHref, linkTarget, contextMethod, redirectHref);
      document.body.appendChild(form);
      form.querySelector('[type="submit"]').click();

      event.preventDefault();
    };

    /**
     * if provided, iterate over searchParams and rebuild the back-to-catalog link to use them
     * @param {?URLSearchParams} searchUrl
     */
    Blacklight.clientAppliedParams = function(storedSearch) {
      if (storedSearch) {
        const appliedParams = document.querySelector('#appliedParams');
        if (appliedParams) {
          const backToCatalogEle = appliedParams.querySelector('.back-to-catalog');
          if (backToCatalogEle) {
            const backToCatalogUrl = new URL(backToCatalogEle.href);
            backToCatalogEle.href = `${backToCatalogUrl.pathname}?${storedSearch.toString()}`;
            backToCatalogEle.removeAttribute('aria-disabled');
            backToCatalogEle.hidden = false;
          }
        }
      }
    };

    /**
     * reassign a link element's href, or delete the element if it is not given
     * remove the aria-disabled attribute if an href is assigned
     * @param {Element} linkEle
     * @param {?string} storedSearch
     */
    const setHrefOrDelete = function(linkEle, url) {
      if (!linkEle) return;
      if (url) {
        linkEle.href = url;
        linkEle.removeAttribute('aria-disabled');
      } else {
        linkEle.remove();
      }
    };

    /**
     * reassign an element's HTML content if the element is given
     * @param {?Element} linkEle
     * @param {?string} storedSearch
     */
    const setContent = function(ele, content) {
      if (ele) ele.innerHTML = content;
    };

    /**
     * fetch the JSON data at pageLinksPath for the given search
     * use the fetched data to build the page-links labels and prev/next links
     * @param {string} pageLinksPath
     * @param {?URLSearchParams} storedSearch
     */
    Blacklight.clientPageLinks = function(pageLinksPath, storedSearch) {
      const pageLinksUrl = new URL(pageLinksPath, window.location);
      // pageLinksUrl should already have a counter param, but needs search params
      const prevNextParams = new URLSearchParams(pageLinksUrl.search);
      if (storedSearch) {
        for (const [paramName, paramValue] of storedSearch.entries()) {
          prevNextParams.append(paramName, paramValue);
        }
      }
      fetch(`${pageLinksUrl.pathname}?${prevNextParams.toString()}`)
      .then((response) => response.json())
      .then(function(responseData) {
        if (!responseData.prev && !responseData.next) return;
        document.querySelectorAll('.page-links').forEach(function(pageLinks) {
          setContent(pageLinks.querySelector('.pagination-counter-raw'), responseData.counterRaw);
          setContent(pageLinks.querySelector('.pagination-counter-delimited'), responseData.counterDelimited);
          setContent(pageLinks.querySelector('.pagination-total-raw'), responseData.totalRaw);
          setContent(pageLinks.querySelector('.pagination-total-delimited'), responseData.totalDelimited);
          setHrefOrDelete(pageLinks.querySelector("a[rel='prev']"), responseData.prev);
          setHrefOrDelete(pageLinks.querySelector("a[rel='next']"), responseData.next);
        });
      });
    };

    Blacklight.doSearchContextBehavior();
  })();

  const index = {
    BookmarkToggle,
    ButtonFocus,
    Modal,
    SearchContext,
    onLoad: Blacklight.onLoad
  };

  return index;

}));
//# sourceMappingURL=blacklight.js.map
