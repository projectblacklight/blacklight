(function (callback) {
  if (typeof define === 'function' && define.amd) {
    define(['core/Core'], callback);
  }
  else {
    callback();
  }
}(function () {

/**
 * Represents a Solr parameter.
 *
 * @param properties A map of fields to set. Refer to the list of public fields.
 * @class Parameter
 */
AjaxSolr.Parameter = AjaxSolr.Class.extend(
  /** @lends AjaxSolr.Parameter.prototype */
  {
  /**
   * @param {Object} attributes
   * @param {String} attributes.name The parameter's name.
   * @param {String} [attributes.value] The parameter's value.
   * @param {Object} [attributes.local] The parameter's local parameters.
   */
  constructor: function (attributes) {
    AjaxSolr.extend(this, {
      name: null,
      value: null,
      locals: {}
    }, attributes);
  },

  /**
   * Returns the value. If called with an argument, sets the value.
   *
   * @param {String|Number|String[]|Number[]} [value] The value to set.
   * @returns The value.
   */
  val: function (value) {
    if (value === undefined) {
      return this.value;
    }
    else {
      this.value = value;
    }
  },

  /**
   * Returns the value of a local parameter. If called with a second argument,
   * sets the value of a local parameter.
   *
   * @param {String} name The name of the local parameter.
   * @param {String|Number|String[]|Number[]} [value] The value to set.
   * @returns The value.
   */
  local: function (name, value) {
    if (value === undefined) {
      return this.locals[name];
    }
    else {
      this.locals[name] = value;
    }
  },

  /**
   * Deletes a local parameter.
   *
   * @param {String} name The name of the local parameter.
   */
  remove: function (name) {
    delete this.locals[name];
  },

  /**
   * Returns the Solr parameter as a query string key-value pair.
   *
   * <p>IE6 calls the default toString() if you write <tt>store.toString()
   * </tt>. So, we need to choose another name for toString().</p>
   */
  string: function () {
    var pairs = [];

    for (var name in this.locals) {
      if (this.locals[name]) {
        pairs.push(name + '=' + encodeURIComponent(this.locals[name]));
      }
    }

    var prefix = pairs.length ? '{!' + pairs.join('%20') + '}' : '';

    if (this.value) {
      return this.name + '=' + prefix + this.valueString(this.value);
    }
    // For dismax request handlers, if the q parameter has local params, the
    // q parameter must be set to a non-empty value. In case the q parameter
    // has local params but is empty, use the q.alt parameter, which accepts
    // wildcards.
    else if (this.name == 'q' && prefix) {
      return 'q.alt=' + prefix + encodeURIComponent('*:*');
    }
    else {
      return '';
    }
  },

  /**
   * Parses a string formed by calling string().
   *
   * @param {String} str The string to parse.
   */
  parseString: function (str) {
    var param = str.match(/^([^=]+)=(?:\{!([^\}]*)\})?(.*)$/);
    if (param) {
      var matches;

      while (matches = /([^\s=]+)=(\S*)/g.exec(decodeURIComponent(param[2]))) {
        this.locals[matches[1]] = decodeURIComponent(matches[2]);
        param[2] = param[2].replace(matches[0], ''); // Safari's exec seems not to do this on its own
      }

      if (param[1] == 'q.alt') {
        this.name = 'q';
        // if q.alt is present, assume it is because q was empty, as above
      }
      else {
        this.name = param[1];
        this.value = this.parseValueString(param[3]);
      }
    }
  },

  /**
   * Returns the value as a URL-encoded string.
   *
   * @private
   * @param {String|Number|String[]|Number[]} value The value.
   * @returns {String} The URL-encoded string.
   */
  valueString: function (value) {
    value = AjaxSolr.isArray(value) ? value.join(',') : value;
    return encodeURIComponent(value);
  },

  /**
   * Parses a URL-encoded string to return the value.
   *
   * @private
   * @param {String} str The URL-encoded string.
   * @returns {Array} The value.
   */
  parseValueString: function (str) {
    str = decodeURIComponent(str);
    return str.indexOf(',') == -1 ? str : str.split(',');
  }
});

/**
 * Escapes a value, to be used in, for example, an fq parameter. Surrounds
 * strings containing spaces or colons in double quotes.
 *
 * @public
 * @param {String|Number} value The value.
 * @returns {String} The escaped value.
 */
AjaxSolr.Parameter.escapeValue = function (value) {
  // If the field value has a space, colon, quotation mark or forward slash
  // in it, wrap it in quotes, unless it is a range query or it is already 
  // wrapped in quotes.
  if (value.match(/[ :\/"]/) && !value.match(/[\[\{]\S+ TO \S+[\]\}]/) && !value.match(/^["\(].*["\)]$/)) {
    return '"' + value.replace(/\\/g, '\\\\').replace(/"/g, '\\"') + '"';
  }
  return value;
}

}));
