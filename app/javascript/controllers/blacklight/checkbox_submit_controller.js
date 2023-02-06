import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['checkbox', 'label', 'span']
  static values = { present: String, absent: String, inprogress: String }

  async change() {
    this.spanTarget.innerHTML = this.inprogressValue;
    this.labelTarget.setAttribute('disabled', 'disabled');
    this.checkboxTarget.setAttribute('disabled', 'disabled');

    const response = await this.submit();

    this.labelTarget.removeAttribute('disabled')
    this.checkboxTarget.removeAttribute('disabled')

    if (response.ok) {
      const json = await response.json()
      this.updateStateTo(this.checked)
      this.updateGlobalBookmarkCounter(json.bookmarks.count)
    } else {
      alert('Error')
    }
  }

  get checked() {
    return this.checkboxTarget.checked;
  }

  async submit() {
    const method = this.checked ? 'put' : 'delete';

    //Set the Rails hidden field that fakes an HTTP verb
    //properly for current state action.
    this.element.querySelector('input[name=_method]').value = method;

    const response = await fetch(this.element.getAttribute('action'), {
      body: new FormData(this.element),
      method: method.toUpperCase(),
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': document.querySelector('meta[name=csrf-token]')?.content
      }
    })

    return response;
  }

  updateGlobalBookmarkCounter(value) {
    document.querySelector('[data-role=bookmark-counter]').innerHTML = value;
  }

  updateStateTo(state) {
    if (state) {
      this.labelTarget.classList.add('checked')
      this.spanTarget.innerHTML = this.presentValue;
    } else {
      this.labelTarget.classList.remove('checked')
      this.spanTarget.innerHTML = this.absentValue;
    }
  }
}
