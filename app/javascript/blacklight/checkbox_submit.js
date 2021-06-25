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
class CheckboxSubmit {
  constructor(form) {
    this.form = form
    this.cssClass = 'toggle-bookmark'

    //View needs to set data-doc-id so we know a unique value
    //for making DOM id
    const uniqueId = this.form.getAttribute('data-doc-id') || Math.random();
    const id = `${this.cssClass}_${uniqueId}`
    this.checkbox = this._buildCheckbox(this.cssClass, id)
    this.span = this._buildSpan()
    this.label = this._buildLabel(id, this.cssClass, this.checkbox, this.span)

    // if form is currently using method delete to change state,
    // then checkbox is currently checked
    this.checked = (this.form.querySelectorAll('input[name=_method][value=delete]').length != 0);
  }

  _buildCheckbox(cssClass, id) {
    const checkbox = document.createElement('input')
    checkbox.setAttribute('type', 'checkbox')
    checkbox.classList.add(cssClass)
    checkbox.id = id
    return checkbox
  }

  _buildLabel(id, cssClass, checkbox, span) {
    const label = document.createElement('label')
    label.classList.add(cssClass)
    label.for = id

    label.appendChild(checkbox)
    label.appendChild(document.createTextNode(' '))
    label.appendChild(span)
    return label
  }

  _buildSpan() {
    return document.createElement('span')
  }

  _buildCheckboxDiv() {
    const checkboxDiv = document.createElement('div')
    checkboxDiv.classList.add('checkbox')
    checkboxDiv.classList.add(this.cssClass)
    checkboxDiv.appendChild(this.label)
    return checkboxDiv
  }

  render() {
    const children = this.form.children
    Array.from(children).forEach((child) => child.classList.add('hidden'))

    //We're going to use the existing form to actually send our add/removes
    //This works conveneintly because the exact same action href is used
    //for both bookmarks/$doc_id.  But let's take out the irrelevant parts
    //of the form to avoid any future confusion.
    this.form.querySelectorAll('input[type=submit]').forEach((el) => this.form.removeChild(el))
    this.form.appendChild(this._buildCheckboxDiv())
    this.updateStateFor(this.checked)

    this.checkbox.onclick = this._clicked.bind(this)
  }

  async _clicked(evt) {
    this.span.innerHTML = this.form.getAttribute('data-inprogress')
    this.label.setAttribute('disabled', 'disabled');
    this.checkbox.setAttribute('disabled', 'disabled');
    const response = await fetch(this.form.getAttribute('action'), {
      body: new FormData(this.form),
      method: this.form.getAttribute('method').toUpperCase(),
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    this.label.removeAttribute('disabled')
    this.checkbox.removeAttribute('disabled')
    if (response.ok) {
      const json = await response.json()
      this.checked = !this.checked
      this.updateStateFor(this.checked)
      document.querySelector('[data-role=bookmark-counter]').innerHTML = json.bookmarks.count
    } else {
      alert('Error')
    }
  }

  updateStateFor(state) {
    this.checkbox.checked = state

    if (state) {
      this.label.classList.add('checked')
      //Set the Rails hidden field that fakes an HTTP verb
      //properly for current state action.
      this.form.querySelector('input[name=_method]').value = 'delete'
      this.span.innerHTML = this.form.getAttribute('data-present')
    } else {
      this.label.classList.remove('checked')
      this.form.querySelector('input[name=_method]').value = 'put'
      this.span.innerHTML = this.form.getAttribute('data-absent')
    }
  }
}
