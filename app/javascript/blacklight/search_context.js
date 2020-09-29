Blacklight.doSearchContextBehavior = function() {
  if (typeof Blacklight.do_search_context_behavior == 'function') {
    console.warn("do_search_context_behavior is deprecated. Use doSearchContextBehavior instead.");
    return Blacklight.do_search_context_behavior();
  }

  const elements = document.querySelectorAll('a[data-context-href]')
  // Equivalent to Array.from(), but supports ie11
  const nodes = Array.prototype.slice.call(elements)

  nodes.forEach(function(element) {
    element.addEventListener('click', function(e) {
      Blacklight.handleSearchContextMethod.call(e.currentTarget, e)
    })
  })
};

// this is the Rails.handleMethod with a couple adjustments, described inline:
// first, we're attaching this directly to the event handler, so we can check for meta-keys
Blacklight.handleSearchContextMethod = function(event) {
  if (typeof Blacklight.handle_search_context_method == 'function') {
    console.warn("handle_search_context_method is deprecated. Use handleSearchContextMethod instead.");
    return Blacklight.handle_search_context_method(event);
  }
  var link = this

  // instead of using the normal href, we need to use the context href instead
  let href = link.getAttribute('data-context-href')
  let target = link.getAttribute('target')
  let csrfToken = Rails.csrfToken()
  let csrfParam = Rails.csrfParam()
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
