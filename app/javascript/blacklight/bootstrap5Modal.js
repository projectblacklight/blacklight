export default class {
  constructor(modalSelector) {
    this.modalSelector = modalSelector
  }

  get modal() {
    const element = document.querySelector(this.modalSelector)
    return bootstrap.Modal.getOrCreateInstance(element)
  }

  show() {
    this.modal.show()
  }

  hide() {
    this.modal.hide()
  }
}
