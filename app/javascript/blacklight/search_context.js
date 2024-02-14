const SearchContext = (e) => {
  if (e.target.matches('[data-context-href]')) {
    SearchContext.handleSearchContextMethod.call(e.target, e)
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


  let formContent = `<input name="_method" value="post" type="hidden" />
    <input name="redirect" value="${link.getAttribute('href')}" type="hidden" />`

  // check for meta keys.. if set, we should open in a new tab
  if(event.metaKey || event.ctrlKey) {
    form.dataset.turbo = "false";
    target = '_blank';
  }

  if (csrfParam !== undefined && csrfToken !== undefined) {
    formContent += `<input name="${csrfParam}" value="${csrfToken}" type="hidden" />`
  }

  // Must trigger submit by click on a button, else "submit" event handler won't work!
  // https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/submit
  formContent += '<input type="submit" />'

  if (target) { form.setAttribute('target', target); }

  form.style.display = 'none'
  form.innerHTML = formContent
  document.body.appendChild(form)
  form.querySelector('[type="submit"]').click()

  event.preventDefault()
};

document.addEventListener('click', SearchContext)

export default SearchContext
