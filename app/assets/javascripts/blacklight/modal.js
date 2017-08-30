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
Blacklight.modal.modalSelector = "#blacklight-modal";

// Trigger selectors identify forms or hyperlinks that should open
// inside a modal dialog.
Blacklight.modal.triggerLinkSelector  = "a[data-blacklight-modal~=trigger]";
Blacklight.modal.triggerFormSelector  = "form[data-blacklight-modal~=trigger]";

// preserve selectors identify forms or hyperlinks that, if activated already
// inside a modal dialog, should have destinations remain inside the modal -- but
// won't trigger a modal if not already in one.
//
// No need to repeat selectors from trigger selectors, those will already
// be preserved. MUST be manually prefixed with the modal selector,
// so they only apply to things inside a modal.
Blacklight.modal.preserveLinkSelector = Blacklight.modal.modalSelector + ' a[data-blacklight-modal~=preserve]';
Blacklight.modal.preserveFormSelector = Blacklight.modal.modalSelector + ' form[data-blacklight-modal~=preserve]'

Blacklight.modal.containerSelector    = "[data-blacklight-modal~=container]";

Blacklight.modal.modalCloseSelector   = "[data-blacklight-modal~=close]";

// Called on fatal failure of ajax load, function returns content
// to show to user in modal.  Right now called only for extreme
// network errors.
Blacklight.modal.onFailure = function(data) {
  var contents =  "<div class='modal-header'>" +
            "<div class='modal-title'>Network Error</div>" +
            '<button type="button" class="blacklight-modal-close close" data-dismiss="modal" aria-label="Close">' +
            '  <span aria-hidden="true">&times;</span>' +
            '</button>';
  $(Blacklight.modal.modalSelector).find('.modal-content').html(contents);
  $(Blacklight.modal.modalSelector).modal('show');
}

Blacklight.modal.receiveAjax = function (contents) {
    // does it have a data- selector for container?
    // important we don't execute script tags, we shouldn't.
    // code modelled off of JQuery ajax.load. https://github.com/jquery/jquery/blob/master/src/ajax/load.js?source=c#L62
    var container =  $("<div>").
      append( jQuery.parseHTML(contents) ).find( Blacklight.modal.containerSelector ).first();
    if (container.length !== 0) {
      contents = container.html();
    }

    $(Blacklight.modal.modalSelector).find('.modal-content').html(contents);

    // send custom event with the modal dialog div as the target
    var e    = $.Event('loaded.blacklight.blacklight-modal')
    $(Blacklight.modal.modalSelector).trigger(e);
    // if they did preventDefault, don't show the dialog
    if (e.isDefaultPrevented()) return;

    $(Blacklight.modal.modalSelector).modal('show');
};


Blacklight.modal.modalAjaxLinkClick = function(e) {
  e.preventDefault();

  $.ajax({
    url: $(this).attr('href')
  })
  .fail(Blacklight.modal.onFailure)
  .done(Blacklight.modal.receiveAjax)
};

Blacklight.modal.modalAjaxFormSubmit = function(e) {
    e.preventDefault();

    $.ajax({
      url: $(this).attr('action'),
      data: $(this).serialize(),
      type: $(this).attr('method') // POST
    })
    .fail(Blacklight.modal.onFailure)
    .done(Blacklight.modal.receiveAjax)
}



Blacklight.modal.setup_modal = function() {
	// Event indicating blacklight is setting up a modal link,
  // you can catch it and call e.preventDefault() to abort
  // setup.
	var e = $.Event('setup.blacklight.blacklight-modal');
	$("body").trigger(e);
	if (e.isDefaultPrevented()) return;

  // Register both trigger and preserve selectors in ONE event handler, combining
  // into one selector with a comma, so if something matches BOTH selectors, it
  // still only gets the event handler called once.
  $("body").on("click", Blacklight.modal.triggerLinkSelector  + ", " + Blacklight.modal.preserveLinkSelector,
    Blacklight.modal.modalAjaxLinkClick);
  $("body").on("submit", Blacklight.modal.triggerFormSelector + ", " + Blacklight.modal.preserveFormSelector,
    Blacklight.modal.modalAjaxFormSubmit);

  // Catch our own custom loaded event to implement data-blacklight-modal=closed
  $("body").on("loaded.blacklight.blacklight-modal", Blacklight.modal.check_close_modal);

  // we support doing data-dismiss=modal on a <a> with a href for non-ajax
  // use, we need to suppress following the a's href that's there for
  // non-JS contexts.
  $("body ").on("click", Blacklight.modal.modalSelector + " a[data-dismiss~=modal]", function (e) {
    e.preventDefault();
  });
};

// A function used as an event handler on loaded.blacklight.blacklight-modal
// to catch contained data-blacklight-modal=closed directions
Blacklight.modal.check_close_modal = function(event) {
  if ($(event.target).find(Blacklight.modal.modalCloseSelector).length) {
    modal_flashes = $(this).find('.flash_messages');

    $(event.target).modal("hide");
    event.preventDefault();

    main_flashes = $('#main-flashes');
    main_flashes.append(modal_flashes);
    modal_flashes.fadeIn(500);
  }
}

Blacklight.onLoad(function() {
  Blacklight.modal.setup_modal();
});
