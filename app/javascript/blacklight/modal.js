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
import Blacklight from './core'

const Modal = (() => {
  // We keep all our data in Blacklight.modal object.
  // Create lazily if someone else created first.
  if (Blacklight.modal === undefined) {
    Blacklight.modal = {};
  }

  const modal = Blacklight.modal

  // a Bootstrap modal div that should be already on the page hidden
  modal.modalSelector = '#blacklight-modal';

  // Trigger selectors identify forms or hyperlinks that should open
  // inside a modal dialog.
  modal.triggerLinkSelector  = 'a[data-blacklight-modal~=trigger]';
  // Used by the email and sms forms:
  modal.triggerFormSelector  = 'form[data-blacklight-modal~=trigger]';

  // preserve selectors identify forms or hyperlinks that, if activated already
  // inside a modal dialog, should have destinations remain inside the modal -- but
  // won't trigger a modal if not already in one.
  //
  // No need to repeat selectors from trigger selectors, those will already
  // be preserved. MUST be manually prefixed with the modal selector,
  // so they only apply to things inside a modal.
  modal.preserveLinkSelector = modal.modalSelector + ' a[data-blacklight-modal~=preserve]';

  modal.containerSelector    = '[data-blacklight-modal~=container]';

  modal.modalCloseSelector   = '[data-blacklight-modal~=close]';

  // Called on fatal failure of ajax load, function returns content
  // to show to user in modal.  Right now called only for extreme
  // network errors.
  modal.onFailure = function(jqXHR, textStatus, errorThrown) {
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
    $(modal.modalSelector).find('.modal-content').html(contents);
    modal.show();
  }

  modal.receiveAjax = function (contents) {
      // does it have a data- selector for container?
      // important we don't execute script tags, we shouldn't.
      // code modelled off of JQuery ajax.load. https://github.com/jquery/jquery/blob/main/src/ajax/load.js?source=c#L62
      var container =  $('<div>').
        append( jQuery.parseHTML(contents) ).find( modal.containerSelector ).first();
      if (container.length !== 0) {
        contents = container.html();
      }

      $(modal.modalSelector).find('.modal-content').html(contents);

      // send custom event with the modal dialog div as the target
      var e    = $.Event('loaded.blacklight.blacklight-modal')
      $(modal.modalSelector).trigger(e);
      // if they did preventDefault, don't show the dialog
      if (e.isDefaultPrevented()) return;

      modal.show();
  };


  modal.modalAjaxLinkClick = function(e) {
    e.preventDefault();

    fetch($(this).attr('href'))
      .then(response => {
         if (!response.ok) {
           throw new TypeError("Request failed");
         }
         return response.text();
       })
      .then(data => modal.receiveAjax(data))
      .catch(error => modal.onFailure(error))
  };

  modal.modalAjaxFormSubmit = function(e) {
      e.preventDefault();

      $.ajax({
        url: $(this).attr('action'),
        data: $(this).serialize(),
        type: $(this).attr('method') // POST
      })
      .fail(modal.onFailure)
      .done(modal.receiveAjax)
  }

  modal.setupModal = function() {
    // Register both trigger and preserve selectors in ONE event handler, combining
    // into one selector with a comma, so if something matches BOTH selectors, it
    // still only gets the event handler called once.
    $('body').on('click', modal.triggerLinkSelector + ', ' + modal.preserveLinkSelector,
      Blacklight.modal.modalAjaxLinkClick);
    $('body').on('submit', modal.triggerFormSelector, modal.modalAjaxFormSubmit);

    // Catch our own custom loaded event to implement data-blacklight-modal=closed
    $('body').on('loaded.blacklight.blacklight-modal', modal.checkCloseModal);
  };

  // A function used as an event handler on loaded.blacklight.blacklight-modal
  // to catch contained data-blacklight-modal=closed directions
  modal.checkCloseModal = function(event) {
    if ($(event.target).find(modal.modalCloseSelector).length) {
      var modalFlashes = $(this).find('.flash_messages');

      Blacklight.modal.hide(event.target);
      event.preventDefault();

      var mainFlashes = $('#main-flashes');
      mainFlashes.append(modalFlashes);
      modalFlashes.fadeIn(500);
    }
  }

  modal.hide = function(el) {
    if (bootstrap.Modal.VERSION >= "5") {
      bootstrap.Modal.getOrCreateInstance(el || document.querySelector(Blacklight.modal.modalSelector)).hide();
    } else {
      $(el || modal.modalSelector).modal('hide');
    }
  }

  modal.show = function(el) {
    if (bootstrap.Modal.VERSION >= "5") {
      bootstrap.Modal.getOrCreateInstance(el || document.querySelector(Blacklight.modal.modalSelector)).show();
    } else {
      $(el || modal.modalSelector).modal('show');
    }
  }

  Blacklight.onLoad(function() {
    modal.setupModal();
  });
})()

export default Modal
