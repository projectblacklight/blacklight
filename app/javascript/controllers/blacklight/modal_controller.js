import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['content', 'modal']

  connect() {
    this.contentTarget.innerHTML = '<turbo-frame id="modal"></turbo-frame>';
  }

  open() {
    this.modalTarget.showModal();
  }

  close() {
    this.modalTarget.close();
  }
}
