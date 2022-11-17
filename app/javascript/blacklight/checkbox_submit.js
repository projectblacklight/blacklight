/* Converts a "toggle" form, with single submit button to add/remove
   something, like used for Bookmarks, into an AJAXy checkbox instead.
   Apply to a form. Does require certain assumption about the form:
    1) The same form 'action' href must be used for both ADD and REMOVE
       actions, with the different being the hidden input name="_method"
       being set to "put" or "delete" -- that's the Rails method to pretend
       to be doing a certain HTTP verb. So same URL, PUT to add, DELETE
       to remove. This plugin assumes that.
       Plus, the form this is applied to should provide a data-doc-id
       attribute (HTML5-style doc-*) that contains the id/primary key
       of the object in question -- used by plugin for a unique value for
       DOM id's.
  Uses HTML for a checkbox compatible with Bootstrap 4.
   new CheckboxSubmit(document.querySelector('form.something')).render()
*/
export default class CheckboxSubmit {
  constructor(form) {
    this.form = form
    this.cssClass = 'toggle-bookmark'
  }

  _buildCheckbox(cssClass, id) {
    const checkbox = document.createElement('input')
    checkbox.setAttribute('type', 'checkbox')
    checkbox.setAttribute('data-checkboxsubmit-target', 'checkbox')
    checkbox.classList.add(cssClass)
    checkbox.id = id
    return checkbox
  }

  _buildSpan() {
    const span = document.createElement('span')
    span.setAttribute('data-checkboxsubmit-target', 'span')
    return span
  }

  _buildLabel(id, cssClass) {
    const label = document.createElement('label')
    label.classList.add(cssClass)
    label.for = id
    label.setAttribute('data-checkboxsubmit-target', 'label')

    label.appendChild(this._buildCheckbox(cssClass, id))
    label.appendChild(document.createTextNode(' '))
    label.appendChild(this._buildSpan())
    return label
  }

  _buildCheckboxDiv(cssClass) {
    //View needs to set data-doc-id so we know a unique value
    //for making DOM id
    const uniqueId = this.form.getAttribute('data-doc-id') || Math.random();
    const id = `${this.cssClass}_${uniqueId}`

    const checkboxDiv = document.createElement('div')
    checkboxDiv.classList.add('checkbox')
    checkboxDiv.classList.add(this.cssClass)
    checkboxDiv.appendChild(this._buildLabel(id, cssClass))
    return checkboxDiv
  }

  render() {
    if (!this.formTarget.querySelector('div.checkbox')) {
      const children = this.formTarget.children
      Array.from(children).forEach((child) => child.classList.add('hidden'))

      //We're going to use the existing form to actually send our add/removes
      //This works conveneintly because the exact same action href is used
      //for both bookmarks/$doc_id.  But let's take out the irrelevant parts
      //of the form to avoid any future confusion.
      this.formTarget.querySelectorAll('input[type=submit]').forEach((el) => this.formTarget.removeChild(el))
      this.formTarget.appendChild(this._buildCheckboxDiv())
    }
    this.updateStateFor(this.checked)

    this.checkboxTarget.onclick = this._clicked.bind(this)
  }

  async _clicked(evt) {
    this.spanTarget.innerHTML = this.form.getAttribute('data-inprogress')
    this.labelTarget.setAttribute('disabled', 'disabled');
    this.checkboxTarget.setAttribute('disabled', 'disabled');
    const response = await fetch(this.formTarget.getAttribute('action'), {
      body: new FormData(this.formTarget),
      method: this.formTarget.getAttribute('method').toUpperCase(),
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': document.querySelector('meta[name=csrf-token]')?.content
      }
    })
    this.labelTarget.removeAttribute('disabled')
    this.checkboxTarget.removeAttribute('disabled')
    if (response.ok) {
      const json = await response.json()
      this.updateStateFor(!this.checked)
      document.querySelector('[data-role=bookmark-counter]').innerHTML = json.bookmarks.count
    } else {
      alert('Error')
    }
  }

  get checked() {
    return (this.form.querySelectorAll('input[name=_method][value=delete]').length != 0)
  }

  get formTarget() {
    return this.form
  }

  get labelTarget() {
    return this.form.querySelector('[data-checkboxsubmit-target="label"]')
  }

  get checkboxTarget() {
    return this.form.querySelector('[data-checkboxsubmit-target="checkbox"]')
  }

  get spanTarget() {
    return this.form.querySelector('[data-checkboxsubmit-target="span"]')
  }

  updateStateFor(state) {
    this.checkboxTarget.checked = state

    if (state) {
      this.labelTarget.classList.add('checked')
      //Set the Rails hidden field that fakes an HTTP verb
      //properly for current state action.
      this.formTarget.querySelector('input[name=_method]').value = 'delete'
      this.spanTarget.innerHTML = this.form.getAttribute('data-present')
    } else {
      this.labelTarget.classList.remove('checked')
      this.formTarget.querySelector('input[name=_method]').value = 'put'
      this.spanTarget.innerHTML = this.form.getAttribute('data-absent')
    }
  }
}
