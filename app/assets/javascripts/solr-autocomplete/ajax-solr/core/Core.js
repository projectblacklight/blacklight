/**
 * @namespace A unique namespace for the AJAX Solr library.
 */
AjaxSolr = function () {};

/**
 * @namespace Baseclass for all classes
 * @see https://github.com/documentcloud/backbone/blob/51eed189bf4d25877be4acdf51e0a4c6039583c5/backbone.js#L243
 */
AjaxSolr.Class = function(attributes) {
  AjaxSolr.extend(this, attributes);
};

/**
 * A class 'extends' itself into a subclass.
 *
 * @static
 * @param protoProps The properties of the subclass.
 * @returns A function that represents the subclass.
 * @see https://github.com/documentcloud/backbone/blob/51eed189bf4d25877be4acdf51e0a4c6039583c5/backbone.js#L1516
 */
AjaxSolr.Class.extend = function (protoProps, staticProps) {
  var parent = this;
  var child;

  // The constructor function for the new subclass is either defined by you
  // (the "constructor" property in your `extend` definition), or defaulted
  // by us to simply call the parent's constructor.
  if (protoProps && Object.prototype.hasOwnProperty.call(protoProps, 'constructor')) {
    child = protoProps.constructor;
  } else {
    child = function(){ return parent.apply(this, arguments); };
  }

  // Add static properties to the constructor function, if supplied.
  AjaxSolr.extend(child, parent, staticProps);

  // Set the prototype chain to inherit from `parent`, without calling
  // `parent`'s constructor function.
  var Surrogate = function(){ this.constructor = child; };
  Surrogate.prototype = parent.prototype;
  child.prototype = new Surrogate;

  // Add prototype properties (instance properties) to the subclass,
  // if supplied.
  if (protoProps) AjaxSolr.extend(child.prototype, protoProps);

  // Set a convenience property in case the parent's prototype is needed
  // later.
  child.__super__ = parent.prototype;

  return child;
};

/**
 * @static
 * @see https://github.com/documentcloud/underscore/blob/7342e289aa9d91c5aacfb3662ea56e7a6d081200/underscore.js#L789
*/
AjaxSolr.extend = function (child) {
  // From _.extend
  var obj = Array.prototype.slice.call(arguments, 1);

  // From _.extend
  var iterator = function(source) {
    if (source) {
      for (var prop in source) {
        child[prop] = source[prop];
      }
    }
  };

  // From _.each
  if (obj == null) return;
  if (Array.prototype.forEach && obj.forEach === Array.prototype.forEach) {
    obj.forEach(iterator);
  } else if (obj.length === +obj.length) {
    for (var i = 0, l = obj.length; i < l; i++) {
      iterator.call(undefined, obj[i], i, obj);
    }
  } else {
    for (var key in obj) {
      if (Object.prototype.hasOwnProperty.call(obj, key)) {
        iterator.call(undefined, obj[key], key, obj);
      }
    }
  }

  return child;
};

/**
 * @static
 * @param value A value.
 * @param array An array.
 * @returns {Boolean} Whether value exists in the array.
 */
AjaxSolr.inArray = function (value, array) {
  if (array) {
    for (var i = 0, l = array.length; i < l; i++) {
      if (AjaxSolr.equals(array[i], value)) {
        return i;
      }
    }
  }
  return -1;
};

/**
 * @static
 * @param foo A value.
 * @param bar A value.
 * @returns {Boolean} Whether the two given values are equal.
 */
AjaxSolr.equals = function (foo, bar) {
  if (AjaxSolr.isArray(foo) && AjaxSolr.isArray(bar)) {
    if (foo.length !== bar.length) {
      return false;
    }
    for (var i = 0, l = foo.length; i < l; i++) {
      if (foo[i] !== bar[i]) {
        return false;
      }
    }
    return true;
  }
  else if (AjaxSolr.isRegExp(foo) && AjaxSolr.isString(bar)) {
    return bar.match(foo);
  }
  else if (AjaxSolr.isRegExp(bar) && AjaxSolr.isString(foo)) {
    return foo.match(bar);
  }
  else {
    return foo === bar;
  }
};

/**
 * Can't use toString.call(obj) === "[object Array]", as it may return
 * "[xpconnect wrapped native prototype]", which is undesirable.
 *
 * @static
 * @see http://thinkweb2.com/projects/prototype/instanceof-considered-harmful-or-how-to-write-a-robust-isarray/
 * @see http://ajax.googleapis.com/ajax/libs/prototype/1.6.0.3/prototype.js
 */
AjaxSolr.isArray = function (obj) {
  return obj != null && typeof obj == 'object' && 'splice' in obj && 'join' in obj;
};

/**
 * @param obj Any object.
 * @returns {Boolean} Whether the object is a RegExp object.
 */
AjaxSolr.isRegExp = function (obj) {
  return obj != null && (typeof obj == 'object' || typeof obj == 'function') && 'ignoreCase' in obj;
};

/**
 * @param obj Any object.
 * @returns {Boolean} Whether the object is a String object.
 */
AjaxSolr.isString = function (obj) {
  return obj != null && typeof obj == 'string';
};
