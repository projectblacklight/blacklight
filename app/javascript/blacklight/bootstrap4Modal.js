export default class {
  constructor(modalSelector) {
    this.modalSelector = modalSelector
  }

  show() {
    $(this.modalSelector).modal('show')
  }

  hide() {
    $(this.modalSelector).modal('hide')
  }
}
