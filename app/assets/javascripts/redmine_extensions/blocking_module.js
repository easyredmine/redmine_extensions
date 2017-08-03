(function () {
  "use strict";
  /**
   * @type {Object.<String,Array.<Function>>}
   */
  var waitingModules = {};
  /**
   * @type {Object<String,boolean>}
   */
  var registeredModules = {};


  window.EASY = window.EASY || {};
  /**
   * Module constructor. Execute [func] only if [moduleName] is registered
   * Works also, if EASY.registerModule is called after module definition
   * @param {String} moduleName
   * @param {Function} func
   * @param {...*} rest - parameters for [func]
   */
  EASY.module = function easyModule(moduleName, func, rest) {
    if (registeredModules[moduleName]) {
      if (rest !== undefined) {
        func.apply(window, Array.prototype.slice.call(arguments, 2));
      } else {
        func();
      }
      return;
    }
    var modules = waitingModules[moduleName];
    if (!modules) {
      waitingModules[moduleName] = modules = [];
    }
    if (rest) {
      var args = Array.prototype.slice.call(arguments, 2);
      modules.push(function () {
        func.apply(window, args);
      })
    } else {
      modules.push(func);
    }
  };
  /**
   * Enables modules with [moduleName] name
   * If any modules are in waitingModules, they are executed immediately.
   * @param {String} moduleName
   */
  EASY.registerModule = function registerModule(moduleName) {
    registeredModules[moduleName] = true;
    if (waitingModules[moduleName]) {
      var modules = waitingModules[moduleName];
      for (var i = 0; i < modules.length; i++) {
        modules[i]();
      }
      delete waitingModules[moduleName];
    }
  };
})();