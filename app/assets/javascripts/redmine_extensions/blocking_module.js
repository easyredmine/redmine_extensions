(function () {
  "use strict";

  var moduleInstances = {};
  /** @type {Object.<String,EasyModule>} */
  var moduleDefinitions = {};
  /** @type {Array.<Waiter>} */
  var waiters = [];
  /** @type {Object.<String,String>} */
  var urls = {};

  function Waiter(dependencies, callback) {
    this.dependencies = dependencies;
    this.callback = callback;
  }

  /**
   * @property {String} name
   * @property {Array.<String>} dependencies
   * @property {Array.<Waiter>} waiters
   * @constructor
   */
  function EasyModule(moduleName) {
    this.name = moduleName;
    setTimeout(function () {
      executeWaiters();
    }, 0);
  }

  /**
   * @methodOf EasyModule
   */
  EasyModule.prototype.checkDependencies = function () {
    if (!checkDependencies(this.dependencies)) return false;
    var instance = {};
    var waiters = this.waiters;
    for (var i = 0; i < waiters.length; i++) {
      var waiter = waiters[i];
      var instances = waiter.dependencies.map(function (moduleName) {
        return moduleInstances[moduleName];
      });
      instance = waiter.callback.apply(instance, instances) || instance;
    }
    moduleInstances[this.name] = instance;
  };

  function checkDependencies(dependencies) {
    // console.log({dependencies: dependencies,instances:Object.keys(moduleInstances),definitions:Object.keys(moduleDefinitions)});
    for (var i = 0; i < dependencies.length; i++) {
      /** @type {String} */
      var dependency = dependencies[i];
      if (moduleInstances[dependency]) continue;
      if (!moduleDefinitions[dependency]) {

        for (var j = i; j < dependencies.length; j++) {
          loadModule(dependencies[j]);
        }
        return false;
      }
      moduleDefinitions[dependency].checkDependencies();
      if (!moduleInstances[dependency]) return false;
    }
    return true;
  }

  function executeWaiter(waiter) {
    var instances = waiter.dependencies.map(function (moduleName) {
      return moduleInstances[moduleName];
    });
    waiter.callback.apply(window, instances);
  }

  function executeWaiters() {
    var executed = false;
    for (var i = 0; i < waiters.length; i++) {
      var waiter = waiters[i];
      if (checkDependencies(waiter.dependencies)) {
        executeWaiter(waiter);
        executed = true;
        waiters[i] = null;
      }
    }
    waiters = waiters.filter(function (item) {
      return item;
    })
  }

  function loadModule(moduleName) {
    var url = urls[moduleName];
    if (url) {
      EasyGem.dynamic.jsTag(url);
    }
  }

  function findMissingModules() {
    var moduleMap = {};
    for (var i = 0; i < waiters.length; i++) {
      missingModules(waiters[i].dependencies, moduleMap);
    }
    var modules = Object.keys(moduleMap);
    if (modules.length > 0) {
      throw "Missing modules: " + modules.join(", ");
    }
  }

  function missingModules(dependencies, modules) {
    for (var i = 0; i < dependencies.length; i++) {
      /** @type {String} */
      var dependency = dependencies[i];
      if (moduleInstances[dependency]) continue;
      if (!moduleDefinitions[dependency]) {
        modules[dependency] = true;
        continue;
      }
      missingModules(moduleDefinitions[dependency].dependencies, modules);
    }
  }

  /**
   *
   * @type {{urls: Object<String, String>, module: EasyGem.module.module, part: EasyGem.module.part, transform: EasyGem.module.transform, setUrl: EasyGem.module.setUrl}}
   */
  EasyGem.module = {
    /**
     * Object containing urls for modules. Filling the urls is recommended to do in <head>.
     * Use [moduleName] as key and absolute path (with or without a hostname) as value
     *   If url have to be specified later, use EasyGem.module.setUrl() instead.
     * @type {Object<String, String>}
     * @example
     *   EasyGem.module.urls["myModule"] = "/assets/my_module.js"
     */
    urls: urls,
    /**
     * Define module in one separate file. Use this method as first line of the file
     * Module can be downloaded on-demand by loadModules() if url is provided by setUrl() function.
     * @example
     *   EasyGem.module.module("myModule", ["jQuery", "c3"], function($, c3) {
     *     return {
     *       init: function(){
     *         c3.init($("#graph"));
     *       }
     *     }
     *   }
     * @param {String} moduleName
     * @param {Array.<String>} prerequisites - other modules needed for construction of module
     * @param {Function} getter - factory function
     */
    module: function (moduleName, prerequisites, getter) {
      var module = moduleDefinitions[moduleName] = new EasyModule(moduleName);
      module.dependencies = prerequisites;
      module.waiters = [new Waiter(prerequisites, getter)];
    },
    /**
     * Define module part if module code is distributed into many separate files.
     *   For dynamic loading by url, all files have to be combine by pipeline into one.
     * Module is executed only if all [prerequisites] from all parts of the module is fulfilled, but only part's
     *   [prerequisites] will be used as arguments for [getter].
     * [prerequisites] argument can be omitted if no prerequisites are required
     * @param {String} moduleName
     * @param {Array.<String>|Function} prerequisites
     * @param {Function} [getter]
     */
    part: function (moduleName, prerequisites, getter) {
      if (getter === undefined) {
        getter = prerequisites;
        prerequisites = [];
      }
      var module = moduleDefinitions[moduleName];
      if (!module){
        module = moduleDefinitions[moduleName] = new EasyModule(moduleName);
        module.waiters = [];
        module.dependencies = [];
      }
      module.waiters.push(new Waiter(prerequisites, getter));
      for (var i = 0; i < prerequisites.length; i++) {
        var prerequisite = prerequisites[i];
        if (module.dependencies.indexOf(prerequisite) === -1) {
          module.dependencies.push(prerequisite);
        }
      }
    },
    /**
     * Transform simple EasyGem.schedule.require [prerequisite] into proper module.
     * Use it sparingly if module have to be defined for usage in other modules as prerequisite.
     * If named getter is saved by EasyGem.schedule.define, the name can also be used.
     * @param {String} moduleName
     * @param {String|Function} prerequisite - getter function
     * @example
     *   EasyGem.module.transform("c3", function() {
     *     return window.c3;
     *   });
     *     -- OR --
     *   EasyGem.module.transform("c3", "c3");
     */
    transform: function (moduleName, prerequisite) {
      EasyGem.schedule.require(function (instance) {
        moduleInstances[moduleName] = instance;
        executeWaiters();
      }, prerequisite);
    },
    /**
     * Save url for later dynamic load of the module. Use it only if url is defined later in page parsing.
     *   If you can specify url in header, use EasyGem.module.urls object instead;
     * @param {String} moduleName
     * @param {String} url - absolute url of the module file, with or without hostname
     */
    setUrl: function (moduleName, url) {
      urls[moduleName] = url;
      executeWaiters();
    }
  };
  /**
   * Load specified modules and execute [callback].
   * Module instances are constructed if not constructed before.
   * Missing modules are downloaded if url is provided.
   * @param {Array.<String>} moduleNames
   * @param {Function} callback - function with module instances as arguments
   * @example
   *   EasyGem.loadModules(["jQuery", "myModule"], function($, myModule) {
   *     myModule.init($("#my_module_container"));
   *   });
   */
  EasyGem.loadModules = function (moduleNames, callback) {
    var waiter = new Waiter(moduleNames, callback);
    if (checkDependencies(moduleNames)) {
      executeWaiter(waiter);
    } else {
      waiters.push(waiter);
      setTimeout(findMissingModules, 5000);
    }
  };
  /**
   * Same as EasyGem.loadModules, but only for one module.
   * @param {String} moduleName
   * @param {Function} callback - function with the module instance as first argument
   */
  EasyGem.loadModule = function (moduleName, callback) {
    this.loadModules([moduleName], callback);
  };
  var transform = EasyGem.module.transform;
  transform("jQuery", "jQuery");
  transform("jQueryUI", "jQueryUI");

})();