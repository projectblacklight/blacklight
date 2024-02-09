// ALL imports in this dir, including in files imported, should be RELATIVE
// paths to keep things working in the various ways these files get used, at
// both compile time and npm package run time.

import BookmarkToggle from './bookmark_toggle.js'
import ButtonFocus from './button_focus.js'
import Modal from './modal.js'
import Core from './core.js'


export default {
  BookmarkToggle,
  ButtonFocus,
  Modal,
  Core,
  onLoad: Core.onLoad
}
