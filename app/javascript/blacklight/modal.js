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
import ModalForm from './modalForm.js'

const Modal = (() => {
  const modal = {}

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
        </div>`

      document.querySelector(`${modal.modalSelector} .modal-content`).innerHTML = contents

      modal.show();
  }

  // Add the passed in contents to the modal and display it.
  modal.receiveAjax = function (contents) {
      const domparser = new DOMParser();
      const dom = domparser.parseFromString(contents, "text/html")
      // If there is a containerSelector on the document, use its children.
      let elements = dom.querySelectorAll(`${modal.containerSelector} > *`)
      if (elements.length == 0) {
        // If the containerSelector wasn't found, use the whole document
        elements = dom.body.childNodes
      }

      document.querySelector(`${modal.modalSelector} .modal-content`).replaceChildren(...elements)

      modal.show();
  };


  modal.modalAjaxLinkClick = function(e) {
    e.preventDefault();
    const href = e.target.getAttribute('href')
    fetch(href)
      .then(response => {
         if (!response.ok) {
           throw new TypeError("Request failed");
         }
         return response.text();
       })
      .then(data => modal.receiveAjax(data))
      .catch(error => modal.onFailure(error))
  };

  modal.setupModal = function() {
    // Register both trigger and preserve selectors in ONE event handler, combining
    // into one selector with a comma, so if something matches BOTH selectors, it
    // still only gets the event handler called once.
    document.addEventListener('click', (e) => {
      if (e.target.closest(`${modal.triggerLinkSelector}, ${modal.preserveLinkSelector}`))
        modal.modalAjaxLinkClick(e)
      else if (e.target.closest('[data-bl-dismiss="modal"]'))
        modal.hide()
    })
  };

  modal.hide = function (el) {
    const dom = document.querySelector(modal.modalSelector)

    if (!dom.open) return
    dom.close()
  }

  modal.show = function(el) {
    const dom = document.querySelector(modal.modalSelector)

    if (dom.open) return
    dom.showModal()
  }

  modal.setupModal()

  return modal;
})()

export default Modal
