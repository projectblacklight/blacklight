(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory(require('blacklight/bookmark_toggle'), require('blacklight/button_focus'), require('blacklight/modal'), require('blacklight/search_context'), require('blacklight/core')) :
  typeof define === 'function' && define.amd ? define(['blacklight/bookmark_toggle', 'blacklight/button_focus', 'blacklight/modal', 'blacklight/search_context', 'blacklight/core'], factory) :
  (global = typeof globalThis !== 'undefined' ? globalThis : global || self, global.Blacklight = factory(global.BookmarkToggle, global.ButtonFocus, global.Modal, global.SearchContext, global.Core));
})(this, (function (BookmarkToggle, ButtonFocus, Modal, SearchContext, Core) { 'use strict';

  const _interopDefaultLegacy = e => e && typeof e === 'object' && 'default' in e ? e : { default: e };

  const BookmarkToggle__default = /*#__PURE__*/_interopDefaultLegacy(BookmarkToggle);
  const ButtonFocus__default = /*#__PURE__*/_interopDefaultLegacy(ButtonFocus);
  const Modal__default = /*#__PURE__*/_interopDefaultLegacy(Modal);
  const SearchContext__default = /*#__PURE__*/_interopDefaultLegacy(SearchContext);
  const Core__default = /*#__PURE__*/_interopDefaultLegacy(Core);

  const index = {
    BookmarkToggle: BookmarkToggle__default.default,
    ButtonFocus: ButtonFocus__default.default,
    Modal: Modal__default.default,
    SearchContext: SearchContext__default.default,
    onLoad: Core__default.default.onLoad
  };

  return index;

}));
//# sourceMappingURL=blacklight.js.map
