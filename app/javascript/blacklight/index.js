import BookmarkToggle from './bookmark_toggle'
import ButtonFocus from './button_focus'
import FacetLoad from './facet_load'
import Modal from './modal'
import Bootstrap4Modal from './bootstrap4Modal'
import SearchContext from './search_context'
import Core from './core'

// We keep configuration data for the modal in the Core.modal object.
// Create lazily if someone else created first.
if (Core.modal === undefined) {
  Core.modal = {
    modalSelector: '#blacklight-modal' // a Bootstrap modal div that should be already on the page hidden
  }
}

Core.onLoad(function() {
  let bootstrapModal;
  if (typeof(jQuery) !== 'undefined' && jQuery.fn.tooltip.Constructor.VERSION.match(/^4\./)) {
    bootstrapModal = new Bootstrap4Modal(Core.modal.modalSelector)
  } else {
    bootstrapModal = new Bootstrap5Modal(Core.modal.modalSelector)
  }
  Modal(bootstrapModal).setupModal();
});

export default {
  BookmarkToggle,
  ButtonFocus,
  FacetLoad,
  SearchContext,
  onLoad: Core.onLoad
}
