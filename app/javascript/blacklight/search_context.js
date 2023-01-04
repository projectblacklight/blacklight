import Blacklight from './core'

const SearchContext = (() => {
  Blacklight.doSearchContextBehavior = function() {
    // intercept clicks on search results to use search context behavior
    document.addEventListener('click', (e) => {
      if (e.target.matches('[data-context-href]')) {
        Blacklight.handleSearchContextMethod.call(e.target, e)
      }
    })
    // page-links dynamic content depends on a loaded document
    Blacklight.onLoad(() => {
      // if page-links container has a data URL, do client-side search context behaviors
      let clientPageLinks = document.querySelectorAll('.page-links[data-page-links-url]')
      if (clientPageLinks[0]) {
        const storedSearch = new URLSearchParams(sessionStorage.getItem("blacklightSearch"))
        Blacklight.clientAppliedParams(storedSearch)
        Blacklight.clientPageLinks(clientPageLinks[0].getAttribute('data-page-links-url'), storedSearch)
      }
    })
  };

  Blacklight.csrfToken = () => document.querySelector('meta[name=csrf-token]')?.content
  Blacklight.csrfParam = () => document.querySelector('meta[name=csrf-param]')?.content
  Blacklight.searchStorage = () => document.querySelector('meta[name=blacklight-search-storage]')?.content

  /**
   * for a URL, iterate over searchParams and return a hidden form input for each pair
   * @param {URL} searchUrl
   * @returns {string} input element source
   */
   const buildInputsFromSearchParams = function(searchUrl) {
    let inputs = ''
    for (const [paramName, paramValue] of searchUrl.searchParams.entries()) {
      inputs += `<input name="${paramName}" value="${paramValue}" type="hidden" />`
    }
    return inputs
  }

  /**
   * build a submittable form to use in the onClick handler of a search result
   * @param {string} formAction
   * @param {?string} formTarget
   * @param {string} formMethod
   * @param {?string} redirectHref
   */
  const buildSearchContextResultForm = function(formAction, formTarget, formMethod, redirectHref) {
    let actionUrl = new URL(formAction, window.location)
    let csrfToken = Blacklight.csrfToken()
    let csrfParam = Blacklight.csrfParam()
    let form = document.createElement('form')
    form.action = actionUrl.pathname
    form.method = (formMethod == 'get') ? formMethod : 'post'

    // check for meta keys.. if set, we should open in a new tab
    const target = (event.metaKey || event.ctrlKey) ? '_blank' : formTarget
    if (target) form.target = target

    form.style.display = 'none'

    let formContent = buildInputsFromSearchParams(actionUrl)
    if (formMethod != 'get' && formMethod != 'post') formContent += `<input name="_method" value="${formMethod}" type="hidden" />`

    if (redirectHref) {
      formContent += `<input name="redirect" value="${redirectHref}" type="hidden" />`
      if (csrfParam !== undefined && csrfToken !== undefined) {
        formContent += `<input name="${csrfParam}" value="${csrfToken}" type="hidden" />`
      }
    }

    // Must trigger submit by click on a button, else "submit" event handler won't work!
    // https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/submit
    formContent += '<input type="submit" />'

    form.innerHTML = formContent
    return form;
  }

  // this is the Rails.handleMethod with a couple adjustments, described inline:
  // first, we're attaching this directly to the event handler, so we can check for meta-keys
  Blacklight.handleSearchContextMethod = function(event) {
    const link = this
    const clientSearchStorage = Blacklight.searchStorage() == 'client'
    if (clientSearchStorage) sessionStorage.setItem("blacklightSearch", new URLSearchParams(new URL(window.location).search))
    // instead of using the normal href, we need to use the context href instead
    const contextHref = new URL(link.getAttribute('data-context-href'), window.location)
    const linkTarget = link.getAttribute('target')
    const contextMethod = link.getAttribute('data-context-method') || 'post'
    const redirectHref = (clientSearchStorage) ? null : link.getAttribute('href')
    const form = buildSearchContextResultForm(contextHref, linkTarget, contextMethod, redirectHref)
    document.body.appendChild(form)
    form.querySelector('[type="submit"]').click()

    event.preventDefault()
  };

  /**
   * if provided, iterate over searchParams and rebuild the back-to-catalog link to use them
   * @param {?URLSearchParams} searchUrl
   */
  Blacklight.clientAppliedParams = function(storedSearch) {
    if (storedSearch) {
      const appliedParams = document.querySelector('#appliedParams')
      if (appliedParams) {
        const backToCatalogEle = appliedParams.querySelector('.back-to-catalog')
        if (backToCatalogEle) {
          const backToCatalogUrl = new URL(backToCatalogEle.href)
          backToCatalogEle.href = `${backToCatalogUrl.pathname}?${storedSearch.toString()}`
          backToCatalogEle.classList.remove('d-none')
        }
      }
    }
  }

  /**
   * reassign a link element's href, or delete the element if it is not given
   * remove the aria-disabled attribute if an href is assigned
   * @param {Element} linkEle
   * @param {?string} storedSearch
   */
  const setHrefOrDelete = function(linkEle, url) {
    if (!linkEle) return;
    if (url) {
      linkEle.href = url
      linkEle.removeAttribute('aria-disabled')
    } else {
      linkEle.remove()
    }
  }

  /**
   * reassign an element's HTML content if the element is given
   * @param {?Element} linkEle
   * @param {?string} storedSearch
   */
  const setContent = function(ele, content) {
    if (ele) ele.innerHTML = content;
  }

  /**
   * fetch the JSON data at pageLinksPath for the given search
   * use the fetched data to build the page-links labels and prev/next links
   * @param {string} pageLinksPath
   * @param {?URLSearchParams} storedSearch
   */
  Blacklight.clientPageLinks = function(pageLinksPath, storedSearch) {
    const pageLinksUrl = new URL(pageLinksPath, window.location)
    // pageLinksUrl should already have a counter param, but needs search params
    let prevNextParams = new URLSearchParams(pageLinksUrl.search);
    if (storedSearch) {
      for (const [paramName, paramValue] of storedSearch.entries()) {
        prevNextParams.append(paramName, paramValue);
      }
    }
    fetch(`${pageLinksUrl.pathname}?${prevNextParams.toString()}`)
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
      })
    })
  }

  Blacklight.doSearchContextBehavior();
})()

export default SearchContext
