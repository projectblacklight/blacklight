(function (callback) {
  if (typeof define === 'function' && define.amd) {
    define(['core/Core'], callback);
  }
  else {
    callback();
  }
}(function () {

/**
 * The Manager acts as the controller in a Model-View-Controller framework. All
 * public calls should be performed on the manager object.
 *
 * @param properties A map of fields to set. Refer to the list of public fields.
 * @class AbstractManager
 */
AjaxSolr.AbstractManager = AjaxSolr.Class.extend(
  /** @lends AjaxSolr.AbstractManager.prototype */
  {
  /**
   * @param {Object} [attributes]
   * @param {String} [attributes.solrUrl] The fully-qualified URL of the Solr
   *   application. You must include the trailing slash. Do not include the path
   *   to any Solr servlet. Defaults to "http://localhost:8983/solr/"
   * @param {String} [attributes.proxyUrl] If we want to proxy queries through a
   *   script, rather than send queries to Solr directly, set this field to the
   *   fully-qualified URL of the script.
   * @param {String} [attributes.servlet] The default Solr servlet. You may
   *   prepend the servlet with a core if using multiple cores. Defaults to
   *   "servlet".
   */
  constructor: function (attributes) {
    AjaxSolr.extend(this, {
      solrUrl: 'http://localhost:8983/solr/',
      proxyUrl: null,
      servlet: 'select',
      // The most recent response from Solr.
      response: {},
      // A collection of all registered widgets.
      widgets: {},
      // The parameter store for the manager and its widgets.
      store: null,
      // Whether <tt>init()</tt> has been called yet.
      initialized: false
    }, attributes);
  },

  /**
   * An abstract hook for child implementations.
   *
   * <p>This method should be called after the store and the widgets have been
   * added. It should initialize the widgets and the store, and do any other
   * one-time initializations, e.g., perform the first request to Solr.</p>
   *
   * <p>If no store has been set, it sets the store to the basic <tt>
   * AjaxSolr.ParameterStore</tt>.</p>
   */
  init: function () {
    this.initialized = true;
    if (this.store === null) {
      this.setStore(new AjaxSolr.ParameterStore());
    }
    this.store.load(false);
    for (var widgetId in this.widgets) {
      this.widgets[widgetId].init();
    }
    this.store.init();
  },

  /**
   * Set the manager's parameter store.
   *
   * @param {AjaxSolr.ParameterStore} store
   */
  setStore: function (store) { 
    store.manager = this;
    this.store = store;
  },

  /** 
   * Adds a widget to the manager.
   *
   * @param {AjaxSolr.AbstractWidget} widget
   */
  addWidget: function (widget) { 
    widget.manager = this;
    this.widgets[widget.id] = widget;
  },

  /** 
   * Stores the Solr parameters to be sent to Solr and sends a request to Solr.
   *
   * @param {Boolean} [start] The Solr start offset parameter.
   * @param {String} [servlet] The Solr servlet to send the request to.
   */
  doRequest: function (start, servlet) {
    if (this.initialized === false) {
      this.init();
    }
    // Allow non-pagination widgets to reset the offset parameter.
    if (start !== undefined) {
      this.store.get('start').val(start);
    }
    if (servlet === undefined) {
      servlet = this.servlet;
    }

    this.store.save();

    for (var widgetId in this.widgets) {
      this.widgets[widgetId].beforeRequest();
    }

    this.executeRequest(servlet);
  },

  /**
   * An abstract hook for child implementations.
   *
   * <p>Sends the request to Solr, i.e. to <code>this.solrUrl</code> or <code>
   * this.proxyUrl</code>, and receives Solr's response. It should pass Solr's
   * response to <code>handleResponse()</code> for handling.</p>
   *
   * <p>See <tt>managers/Manager.jquery.js</tt> for a jQuery implementation.</p>
   *
   * @param {String} servlet The Solr servlet to send the request to.
   * @param {String} string The query string of the request. If not set, it
   *   should default to <code>this.store.string()</code>
   * @throws If not defined in child implementation.
   */
  executeRequest: function (servlet, string) {
    throw 'Abstract method executeRequest must be overridden in a subclass.';
  },

  /**
   * This method is executed after the Solr response data arrives. Allows each
   * widget to handle Solr's response separately.
   *
   * @param {Object} data The Solr response.
   */
  handleResponse: function (data) {
    this.response = data;

    for (var widgetId in this.widgets) {
      this.widgets[widgetId].afterRequest();
    }
  },

  /**
   * This method is executed if Solr encounters an error.
   *
   * @param {String} message An error message.
   */
  handleError: function (message) {
    window.console && console.log && console.log(message);
  }
});

}));
