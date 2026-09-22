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
  Uses HTML for a checkbox compatible with Bootstrap.
   new CheckboxSubmit(document.querySelector('form.something')).render()
*/
class CheckboxSubmit {
  constructor(form) {
    this.form = form;
  }

  clicked(evt) {
    this.spanTarget.innerHTML = this.form.getAttribute('data-inprogress');
    this.labelTarget.setAttribute('disabled', 'disabled');
    this.checkboxTarget.setAttribute('disabled', 'disabled');
    fetch(this.formTarget.getAttribute('action'), {
      body: new FormData(this.formTarget),
      method: this.formTarget.getAttribute('method').toUpperCase(),
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': document.querySelector('meta[name=csrf-token]')?.content
      }
    }).then((response) => {
      if (response.ok) return response.json();
      return Promise.reject('response was not ok')
    }).then((json) => {
      this.labelTarget.removeAttribute('disabled');
      this.checkboxTarget.removeAttribute('disabled');
      // For accessibility return keyboard focus
      // back to the checkbox after form submission
      this.checkboxTarget.focus();
      this.updateStateFor(!this.checked);
      this.bookmarksCounter().forEach(counter => {
        counter.innerHTML = json.bookmarks.count;
      });

      var e = new CustomEvent('bookmark.blacklight', { detail: { checked: this.checked }, bubbles: true });
      this.formTarget.dispatchEvent(e);
    }).catch((error) => {
      this.handleError(error);
    });
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

  bookmarksCounter() {
    return document.querySelectorAll('[data-role="bookmark-counter"]')
  }

  handleError() {
    alert("Unable to save the bookmark at this time.");
  }

  updateStateFor(state) {
    if (state) { this.checkboxTarget.setAttribute('checked', state); }
    else { this.checkboxTarget.removeAttribute('checked'); }

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

const BookmarkToggle = (e) => {
  const elementType = e.target.getAttribute('data-checkboxsubmit-target');
  if (elementType == 'checkbox' || elementType == 'label') {
    const form = e.target.closest('form');
    if (form) new CheckboxSubmit(form).clicked(e);
    if (e.code == 'Space') e.preventDefault();
  }
};

document.addEventListener('click', BookmarkToggle);
document.addEventListener('keydown', function (e) {
  if (e.key === 'Enter' || e.code == 'Space') { BookmarkToggle(e); } }
);

const ButtonFocus = (e) => {
  // Button clicks should change focus. As of 10/3/19, Firefox for Mac and
  // Safari both do not set focus to a button on button click.
  // See https://zellwk.com/blog/inconsistent-button-behavior/ for background information
  if (e.target.matches('[data-bs-toggle="collapse"]')) {
    e.target.focus();
  }
};

document.addEventListener('click', ButtonFocus);

const Core = function() {
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
      } else {
        listeners.push('DOMContentLoaded');
      }

      return listeners;
    }
  };
}();

// turbo triggers turbo:load events on page transition
// If app isn't using turbo, this event will never be triggered, no prob.
Core.listeners().forEach(function(listener) {
  document.addEventListener(listener, function() {
    Core.activate();
  });
});

Core.onLoad(function () {
  const elem = document.querySelector('.no-js');

  // The "no-js" class may already have been removed because this function is
  // run on every turbo:load event, in that case, it won't find an element.
  if (!elem) return;

  elem.classList.remove('no-js');
  elem.classList.add('js');
});

/*!
 * Color mode toggler for Blacklight
 * Based on Bootstrap's color mode toggler (https://getbootstrap.com/docs/5.3/customize/color-modes/#javascript)
 */


const ColorThemeSwitcher = (() => {

  const getStoredTheme = () => localStorage.getItem('theme');
  const setStoredTheme = theme => localStorage.setItem('theme', theme);

  const getPreferredTheme = () => {
    const storedTheme = getStoredTheme();
    if (storedTheme) {
      return storedTheme
    }
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
  };

  const setTheme = theme => {
    if (theme === 'auto') {
      document.documentElement.setAttribute('data-bs-theme', window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
    } else {
      document.documentElement.setAttribute('data-bs-theme', theme);
    }
  };

  const showActiveTheme = (theme, focus = false) => {
    const themeSwitcher = document.querySelector('#bl-theme-switcher');
    if (!themeSwitcher) return

    // Reset all dropdown items
    document.querySelectorAll('[data-bs-theme-value]').forEach(element => {
      element.classList.remove('active');
      element.setAttribute('aria-pressed', 'false');
      const check = element.querySelector('.bl-theme-check');
      if (check) check.classList.add('d-none');
    });

    // Activate the selected item
    const btnToActive = document.querySelector(`[data-bs-theme-value="${theme}"]`);
    if (btnToActive) {
      btnToActive.classList.add('active');
      btnToActive.setAttribute('aria-pressed', 'true');
      const check = btnToActive.querySelector('.bl-theme-check');
      if (check) check.classList.remove('d-none');
    }

    // Swap the toggle button icon
    themeSwitcher.querySelectorAll('.bl-theme-icon').forEach(icon => icon.classList.add('d-none'));
    const activeIcon = themeSwitcher.querySelector(`.bl-theme-icon[data-bl-theme-icon="${theme}"]`);
    if (activeIcon) activeIcon.classList.remove('d-none');

    themeSwitcher.setAttribute('aria-label', `Toggle theme (${theme})`);

    if (focus) {
      themeSwitcher.focus();
    }
  };

  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
    const storedTheme = getStoredTheme();
    if (storedTheme !== 'light' && storedTheme !== 'dark') {
      setTheme(getPreferredTheme());
    }
  });

  document.addEventListener('click', e => {
    const btn = e.target.closest('[data-bs-theme-value]');
    if (!btn) return

    const theme = btn.getAttribute('data-bs-theme-value');
    setStoredTheme(theme);
    setTheme(theme);
    showActiveTheme(theme, true);
  });

  Core.onLoad(() => showActiveTheme(getPreferredTheme()));

  return { setTheme, getPreferredTheme, showActiveTheme }
})();

// Usage:
// ```
// const basicFunction = (entry) => console.log(entry)
// const debounced = debounce(basicFunction("I should only be called once"));
//
// debounced // does NOT print to the screen because it is invoked again less than 200 milliseconds later
// debounced // does print to the screen
// ```
function debounce(func, timeout = 200) {
    let timer;
    return (...args) => {
      clearTimeout(timer);
      timer = setTimeout(() => { func.apply(this, args); }, timeout);
    };
}

const FacetSuggest = async (e) => {
  if (e.target.matches('.facet-suggest')) {
    const queryFragment = e.target.value?.trim();
    const facetField = e.target.dataset.facetField;
    const facetArea = document.querySelector('.facet-extended-list');
    const prevNextLinks = document.querySelectorAll('.prev_next_links');

    if (!facetField) { return; }

    // Get the search params from the current query so the facet suggestions
    // can retain that context.
    const facetSearchContext = e.target.dataset.facetSearchContext;
    const url = new URL(facetSearchContext, window.location.origin);

    // Drop facet.page so a filtered suggestion list will always start on page 1
    url.searchParams.delete('facet.page');
    // add our queryFragment for facet filtering
    url.searchParams.append('query_fragment', queryFragment);

    const facetSearchParams = url.searchParams.toString();
    const basePathComponent = url.pathname.split('/')[1];

    const urlToFetch = `/${basePathComponent}/facet_suggest/${facetField}?${facetSearchParams}`;

    const response = await fetch(urlToFetch);
    if (response.ok) {
        const blob = await response.blob();
        const text = await blob.text();

        if (text && facetArea) {
            facetArea.innerHTML = text;
        }
    }

    // Hide the prev/next links when a user enters text in the facet
    // suggestion input. They don't work with a filtered list.
    prevNextLinks.forEach(element => {
      element.classList.toggle('invisible', !!queryFragment);
    });

    // Add a class to distinguish suggested facet values vs. regular.
    facetArea.classList.toggle('facet-suggestions', !!queryFragment);
  }
};

document.addEventListener('input', debounce(FacetSuggest));

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
        <button type="button" class="btn-close" data-bl-dismiss="modal" aria-hidden="true">×</button>
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
  const modal = {};

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
        <button type="button" class="blacklight-modal-close btn-close" data-bl-dismiss="modal" aria-label="Close">
        </button>
        </div>
        <div class="modal-body">
          <p>Expected a successful response from the server, but got an error</p>
          <pre>${this.url}\n${error}</pre>
        </div>`;

      modal.target().querySelector('.modal-content').innerHTML = contents;

      modal.show();
  };

  // Add the passed in contents to the modal and display it.
  // We have specific handling so that scripts returned from the ajax call are executed.
  // This enables adding a script like recaptcha to prevent bots from sending emails.
  modal.receiveAjax = function (contents) {
    const domparser = new DOMParser();
    const dom = domparser.parseFromString(contents, "text/html");
    // If there is a containerSelector on the document, use its children.
    let elements = dom.querySelectorAll(`${modal.containerSelector} > *`);
    const frag = document.createDocumentFragment();
    if (elements.length == 0) {
      // If the containerSelector wasn't found, use the whole document
      elements = dom.body.childNodes;
    }
    elements.forEach((el) => frag.appendChild(el));
    modal.activateScripts(frag);

    modal.target().querySelector('.modal-content').replaceChildren(frag);

    // send custom event with the modal dialog div as the target
    var e = new CustomEvent('loaded.blacklight.blacklight-modal', { bubbles: true, cancelable: true });
    modal.target().dispatchEvent(e);

    // if they did preventDefault, don't show the dialog
    if (e.defaultPrevented) return;
    modal.show();
  };

  // DOMParser doesn't allow scripts to be executed.  This fixes that.
  modal.activateScripts = function (frag) {
    frag.querySelectorAll('script').forEach((script) => {
      const fixedScript = document.createElement('script');
      fixedScript.src = script.src;
      fixedScript.async = false;
      script.parentNode.replaceChild(fixedScript, script);
    });
  };

  modal.modalAjaxLinkClick = function(e) {
    e.preventDefault();
    const href = e.target.closest('a').getAttribute('href');
    fetch(href, { headers: { 'X-Requested-With': 'XMLHttpRequest' }})
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
    // Register several click handlers in ONE event handler for efficiency
    //
    // * close button OR click on backdrop (modal.modalSelector) closes modal
    // * trigger and preserve link in modal functionality -- if somethign matches both trigger and
    //   preserve, still only called once.
    document.addEventListener('click', (e) => {
      if (e.target.closest(`${modal.triggerLinkSelector}, ${modal.preserveLinkSelector}`))
        modal.modalAjaxLinkClick(e);
      else if (e.target.matches(`${modal.modalSelector}`) || e.target.closest('[data-bl-dismiss="modal"]'))
        modal.hide();
    });

    // Make sure user-agent dismissal of html 'dialog', etc `esc` key, triggers
    // our hide logic, including events and scroll restoration.
    const modalDom = modal.target();
    if (modalDom) {
      modal.target().addEventListener('cancel', (e) => {
        e.preventDefault(); // 'hide' will close the modal unless cancelled

        modal.hide();
      });
    }
  };

  modal.hide = function (el) {
    const dom = modal.target();

    if (!dom.open) return

    var e = new CustomEvent('hide.blacklight.blacklight-modal', { bubbles: true, cancelable: true });
    dom.dispatchEvent(e);

    dom.close();

    // Turn body scrolling back to what it was
    document.body.style["overflow"] = modal.originalBodyOverflow;
    document.body.style["padding-right"] = modal.originalBodyPaddingRight;
    modal.originalBodyOverflow = undefined;
    modal.originalBodyPaddingRight = undefined;
  };

  modal.show = function(el) {
    const dom = modal.target();

    if (dom.open) return

    var e = new CustomEvent('show.blacklight.blacklight-modal', { bubbles: true, cancelable: true });
    dom.dispatchEvent(e);

    dom.showModal();

    // Turn off body scrolling
    modal.originalBodyOverflow = document.body.style['overflow'];
    modal.originalBodyPaddingRight = document.body.style['padding-right'];
    document.body.style["overflow"] = "hidden";
    document.body.style["padding-right"] = "0px";
  };

  modal.target = function() {
    return document.querySelector(modal.modalSelector);
  };

  modal.setupModal();

  return modal;
})();

const SearchContext = (e) => {
  const contextLink = e.target.closest('[data-context-href]');
  if (contextLink) {
    SearchContext.handleSearchContextMethod.call(contextLink, e);
  }
};

SearchContext.csrfToken = () => document.querySelector('meta[name=csrf-token]')?.content;
SearchContext.csrfParam = () => document.querySelector('meta[name=csrf-param]')?.content;

// this is the Rails.handleMethod with a couple adjustments, described inline:
// first, we're attaching this directly to the event handler, so we can check for meta-keys
SearchContext.handleSearchContextMethod = function(event) {
  const link = this;

  // instead of using the normal href, we need to use the context href instead
  let href = link.getAttribute('data-context-href');
  let target = link.getAttribute('target');
  let csrfToken = SearchContext.csrfToken();
  let csrfParam = SearchContext.csrfParam();
  let form = document.createElement('form');
  form.method = 'post';
  form.action = href;


  let formContent = `<input name="_method" value="post" type="hidden" />
    <input name="redirect" value="${link.getAttribute('href')}" type="hidden" />`;

  // check for meta keys.. if set, we should open in a new tab
  if(event.metaKey || event.ctrlKey) {
    form.dataset.turbo = "false";
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

document.addEventListener('click', SearchContext);

const index = {
  BookmarkToggle,
  ButtonFocus,
  ColorThemeSwitcher,
  FacetSuggest,
  Modal,
  SearchContext,
  Core,
  onLoad: Core.onLoad
};

export { index as default };
//# sourceMappingURL=blacklight.esm.js.map
