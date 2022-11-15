import BookmarkToggle from './bookmark_toggle'
import ButtonFocus from './button_focus'
import Modal from './modal'
import SearchContext from './search_context'
import Core from './core'

Stimulus.register('blacklight-bookmark', BookmarkToggle)

export default {
  BookmarkToggle,
  ButtonFocus,
  Modal,
  SearchContext,
  onLoad: Core.onLoad
}
