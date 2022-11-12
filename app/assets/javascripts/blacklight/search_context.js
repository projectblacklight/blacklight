import Blacklight from './core'

const SearchContext = (() => {
  Blacklight.doSearchContextBehavior = function() {
    const elements = document.querySelectorAll('a[data-context-href]')
    const nodes = Array.from(elements)

    nodes.forEach(function(element) {
      element.addEventListener('click', function(e) {
        Blacklight.handleSearchContextMethod.call(e.currentTarget, e)
      })
    })
  };

  Blacklight.csrfToken = () => document.querySelector('meta[name=csrf-token]')?.content
  Blacklight.csrfParam = () => document.querySelector('meta[name=csrf-param]')?.content

  // this is the Rails.handleMethod with a couple adjustments, described inline:
  // first, we're attaching this directly to the event handler, so we can check for meta-keys
  Blacklight.handleSearchContextMethod = function(event) {
    const link = this

    // instead of using the normal href, we need to use the context href instead
    let href = link.getAttribute('data-context-href')
    let target = link.getAttribute('target')
    let csrfToken = Blacklight.csrfToken()
    let csrfParam = Blacklight.csrfParam()
    let form = document.createElement('form')
    form.method = 'post'
    form.action = href


    let formContent = `<input name="_method" value="post" type="hidden" />
      <input name="redirect" value="${link.getAttribute('href')}" type="hidden" />`

    // check for meta keys.. if set, we should open in a new tab
    if(event.metaKey || event.ctrlKey) {
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
    event.stopPropagation()
  };

  Blacklight.onLoad(function() {
    Blacklight.doSearchContextBehavior();
  });
})()

export default SearchContext
