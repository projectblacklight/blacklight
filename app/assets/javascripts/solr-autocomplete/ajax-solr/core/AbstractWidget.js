(function (callback) {
  if (typeof define === 'function' && define.amd) {
    define(['core/Core'], callback);
  }
  else {
    callback();
  }
}(function () {

/**
 * Baseclass for all widgets. 
 * 
 * Provides abstract hooks for child classes.
 *
 * @param properties A map of fields to set. May be new or public fields.
 * @class AbstractWidget
 */
AjaxSolr.AbstractWidget = AjaxSolr.Class.extend(
  /** @lends AjaxSolr.AbstractWidget.prototype */
  {
  /**
   * @param {Object} attributes
   * @param {String} attributes.id A unique identifier of this widget.
   * @param {String} [attributes.target] The CSS selector for this widget's
   *   target HTML element, e.g. a specific <tt>div</tt> or <tt>ul</tt>. A
   *   Widget is usually implemented to perform all its UI changes relative to
   *   its target HTML element.
   * @param {Number} [attributes.start] The offset parameter. Set this field to
   *   make the widget reset the offset parameter to the given value on each
   *   request.
   * @param {String} [attributes.servlet] The Solr servlet for this widget. You
   *   may prepend the servlet with a core if using multiple cores. If none is
   *   set, it will default to the manager's servlet.
   */
  constructor: function (attributes) {
    AjaxSolr.extend(this, {
      id: null,
      target: null,
      start: undefined,
      servlet: undefined,
      // A reference to the widget's manager.
      manager: null
    }, attributes);
  },

  /**
   * An abstract hook for child implementations.
   *
   * <p>This method should do any necessary one-time initializations.</p>
   */
  init: function () {},

  /** 
   * An abstract hook for child implementations.
   *
   * <p>This method is executed before the Solr request is sent.</p>
   */
  beforeRequest: function () {},

  /**
   * An abstract hook for child implementations.
   *
   * <p>This method is executed after the Solr response is received.</p>
   */
  afterRequest: function () {},

  /**
   * A proxy to the manager's doRequest method.
   *
   * @param {Boolean} [start] The Solr start offset parameter.
   * @param {String} [servlet] The Solr servlet to send the request to.
   */
  doRequest: function (start, servlet) {
    this.manager.doRequest(start || this.start, servlet || this.servlet);
  }
});

}));
