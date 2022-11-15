import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['label', 'checkbox']
  static values = {
    present: String,
    absent: String,
    inprogress: String,
    url: String
  }

  async toggle() {
    this.labelTarget.innerHTML = this.inprogressValue
    this.labelTarget.setAttribute('disabled', 'disabled');
    this.element.setAttribute('disabled', 'disabled');
    const id = this.element.id
    const response = await fetch(this.urlValue, {
      body: { id: id },
      method: this.checkboxTarget.checked ? 'PUT' : 'DELETE',
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': document.querySelector('meta[name=csrf-token]')?.content
      }
    })
    this.labelTarget.removeAttribute('disabled')
    this.element.removeAttribute('disabled')
    if (response.ok) {
      const json = await response.json()
      this.checked = !this.checked
      this.labelTarget.innerHTML = this.checked ? this.presentValue : this.absentValue

      document.querySelector('[data-role=bookmark-counter]').innerHTML = json.bookmarks.count
    } else {
      alert('There was a problem bookmarking this document')
    }
  }
}
