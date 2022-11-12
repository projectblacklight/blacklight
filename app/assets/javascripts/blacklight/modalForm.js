// The email and sms forms are displayed inside a modal.  When the form is submitted,
// this script closes the modal and puts the output on the main part of the page.
// By default it is rendering catalog/sms_success and catalog/email_succcess.
// These templates deliver a payload of the format used by turbo-streams.
// See https://turbo.hotwired.dev/handbook/streams
// That format allows a downstream application to override the template to define
// multiple customizable areas of the page to get updated.
export default class {
    constructor(errorHandler, badRequestHandler, hideModal) {
      this.errorHandler = errorHandler
      this.badRequestHandler = badRequestHandler
      this.hideModal = hideModal
    }

    get triggerFormSelector() {
      return 'form[data-blacklight-modal~=trigger]'
    }

    bind() {
      document.addEventListener('submit', (e) => {
         if (e.target.matches(this.triggerFormSelector))
          this.onSubmit(e)
      })
    }

    // This is like a light-weight version of turbo that only supports append presently.
    updateTurboStream(data) {
        this.hideModal()
        const domparser = new DOMParser();
        const dom = domparser.parseFromString(data, "text/html")
        dom.querySelectorAll("turbo-stream[action='append']").forEach((node) => {
          const target = node.getAttribute('target')
          const element = document.getElementById(target)
          if (element)
            element.append(node.querySelector('template').content.cloneNode(true))
          else
            console.error(`Unable to find an element on the page with and ID of "${target}""`)
        })
    }

    onSubmit(e) {
        e.preventDefault();
        const form = e.target
        fetch(form.action, {
            body: new FormData(form),
            headers: { "X-Requested-With": "XMLHttpRequest" }, // Ensures rails will return true when checking request.xhr?
            method: form.method,
          })
          .then(response => {
             if (response.status === 422) {
               return response.text().then(content => this.badRequestHandler(content) )
             }
             if (!response.ok) {
               throw new TypeError("Request failed");
             }
             response.text().then(content => this.updateTurboStream(content))
           })
          .catch(error => this.errorHandler(error))
    }
}
