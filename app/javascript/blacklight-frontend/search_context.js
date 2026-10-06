const SearchContext = (e) => {
  const contextLink = e.target.closest('[data-context-href]')
  if (contextLink) {
    SearchContext.handleSearchContextMethod.call(contextLink, e)
  }
}

SearchContext.csrfToken = () => document.querySelector('meta[name=csrf-token]')?.content
SearchContext.csrfParam = () => document.querySelector('meta[name=csrf-param]')?.content

// this is the Rails.handleMethod with a couple adjustments, described inline:
// first, we're attaching this directly to the event handler, so we can check for meta-keys
SearchContext.handleSearchContextMethod = function(event) {
  const link = this

  // instead of using the normal href, we need to use the context href instead
  let href = link.getAttribute('data-context-href')
  let target = link.getAttribute('target')
  let csrfToken = SearchContext.csrfToken()
  let csrfParam = SearchContext.csrfParam()
  let form = document.createElement('form')
  form.method = 'post'
  form.action = href


  const appendHiddenInput = (name, value) => {
    const input = document.createElement('input')
    input.type = 'hidden'
    input.name = name
    input.value = value
    form.appendChild(input)
  }

  appendHiddenInput('_method', 'post')
  appendHiddenInput('redirect', link.getAttribute('href'))

  // check for meta keys.. if set, we should open in a new tab
  if(event.metaKey || event.ctrlKey) {
    form.dataset.turbo = "false";
    target = '_blank';
  }

  if (csrfParam !== undefined && csrfToken !== undefined) {
    appendHiddenInput(csrfParam, csrfToken)
  }

  // Must trigger submit by click on a button, else "submit" event handler won't work!
  // https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/submit
  const submit = document.createElement('input')
  submit.type = 'submit'
  form.appendChild(submit)

  if (target) { form.setAttribute('target', target); }

  form.style.display = 'none'
  document.body.appendChild(form)
  submit.click()

  event.preventDefault()
};

document.addEventListener('click', SearchContext)

export default SearchContext
