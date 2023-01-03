import Blacklight from './core'

const SearchContext = (() => {
  Blacklight.doSearchContextBehavior = function() {
    document.addEventListener('click', (e) => {
      if (e.target.matches('[data-context-href]')) {
        Blacklight.handleSearchContextMethod.call(e.target, e)
      }
    })
  };

  Blacklight.csrfToken = () => document.querySelector('meta[name=csrf-token]')?.content
  Blacklight.csrfParam = () => document.querySelector('meta[name=csrf-param]')?.content
  Blacklight.searchStorage = () => document.querySelector('meta[name=blacklight-search-storage]')?.content

  // this is the Rails.handleMethod with a couple adjustments, described inline:
  // first, we're attaching this directly to the event handler, so we can check for meta-keys
  Blacklight.handleSearchContextMethod = function(event) {
    const link = this

    // instead of using the normal href, we need to use the context href instead
    let contextUrl = new URL(link.getAttribute('data-context-href'), window.location)
    let target = link.getAttribute('target')
    let csrfToken = Blacklight.csrfToken()
    let csrfParam = Blacklight.csrfParam()
    let form = document.createElement('form')
    form.action = contextUrl.pathname;
    const formMethod = link.getAttribute('data-context-method') || 'post'
    form.method = (formMethod == 'get') ? formMethod : 'post'

    let formContent = ''
    for (const [paramName, paramValue] of contextUrl.searchParams.entries()) {
      formContent += `<input name="${paramName}" value="${paramValue}" type="hidden" />`
    }
    if (formMethod != 'get' && formMethod != 'post') formContent += `<input name="_method" value="${formMethod}" type="hidden" />`

    if (Blacklight.searchStorage() == 'client') {
      sessionStorage.setItem("blacklightSearch", new URLSearchParams(new URL(window.location).search))
    } else {
      formContent += `<input name="redirect" value="${link.getAttribute('href')}" type="hidden" />`
      if (csrfParam !== undefined && csrfToken !== undefined) {
        formContent += `<input name="${csrfParam}" value="${csrfToken}" type="hidden" />`
      }
    }
    // check for meta keys.. if set, we should open in a new tab
    if(event.metaKey || event.ctrlKey) {
      target = '_blank';
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

  Blacklight.doSearchContextBehavior();

  const clientAppliedParams = function(storedSearch) {
    if (storedSearch) {
      let backToCatalogParams = new URLSearchParams();
      for (const [paramName, paramValue] of storedSearch.entries()) {
        backToCatalogParams.append(paramName, paramValue);
      }
      const appliedParams = document.querySelector('#appliedParams')
      if (appliedParams) {
        const backToCatalogEle = appliedParams.querySelector('.back-to-catalog')
        if (backToCatalogEle) {
          const backToCatalogUrl = new URL(backToCatalogEle.href)
          backToCatalogEle.href = `${backToCatalogUrl.pathname}?${backToCatalogParams.toString()}`
          backToCatalogEle.classList.remove('d-none')
        }
      }
    }
  }
  const clientPrevNext = function(prevNextPath, storedSearch) {
    const prevNextUrl = new URL(prevNextPath, window.location)
    // prevNextUrl should have a counter param, but needs search params
    let prevNextParams = new URLSearchParams(prevNextUrl.search);
    if (storedSearch) {
      for (const [paramName, paramValue] of storedSearch.entries()) {
        prevNextParams.append(paramName, paramValue);
      }
    }
    const setHrefOrDelete = function(linkEle, url) {
      if (!linkEle) return;
      if (url) {
        linkEle.href = url
      } else {
        linkEle.remove()
      }
    }
    const setContent = function(ele, content) {
      if (!ele) return;
      ele.innerHTML = content;
    }
    fetch(`${prevNextUrl.pathname}?${prevNextParams.toString()}`)
    .then((response) => response.json())
    .then(function(responseData) {
      if (!responseData.prev && !responseData.next) return;
      document.querySelectorAll('.page-links').forEach(function(pageLinks) {
        setContent(pageLinks.querySelector('.pagination-counter-raw'), responseData.counterRaw)
        setContent(pageLinks.querySelector('.pagination-counter-delimited'), responseData.counterDelimited)
        setContent(pageLinks.querySelector('.pagination-total-raw'), responseData.totalRaw)
        setContent(pageLinks.querySelector('.pagination-total-delimited'), responseData.totalDelimited)
        setHrefOrDelete(pageLinks.querySelector("a[rel='prev']"), responseData.prev)
        setHrefOrDelete(pageLinks.querySelector("a[rel='next']"), responseData.next)
        pageLinks.classList.remove('d-none')
      })
    })
  }
  Blacklight.onLoad(function(){
    let clientPageLinks = document.querySelectorAll('.page-links[data-page-links-url]')
    if (clientPageLinks[0]) {
      const storedSearch = new URLSearchParams(sessionStorage.getItem("blacklightSearch"))
      clientAppliedParams(storedSearch)
      clientPrevNext(clientPageLinks[0].getAttribute('data-page-links-url'), storedSearch)
    }
  })
})()

export default SearchContext
