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
   * @type {{urls: Object<String, String>, module: EasyGem.module.module, part: EasyGem.module.part, head: EasyGem.module.head, transform: EasyGem.module.transform, setUrl: EasyGem.module.setUrl}}
   */
  EasyGem.module = {
    urls: urls,
    /**
     * Define
     * @param {String} moduleName
     * @param {Array.<String>} prerequisites
     * @param {Function} getter
     */
    module: function (moduleName, prerequisites, getter) {
      var module = moduleDefinitions[moduleName] = new EasyModule(moduleName);
      module.dependencies = prerequisites;
      module.waiters = [new Waiter(prerequisites, getter)];
    },
    /**
     *
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
      if (!module) throw "Missing module head " + moduleName;
      module.waiters.push(new Waiter(prerequisites, getter));
      for (var i = 0; i < prerequisites.length; i++) {
        var prerequisite = prerequisites[i];
        if (module.dependencies.indexOf(prerequisite) === -1) {
          module.dependencies.push(prerequisite);
        }
      }
    },
    /**
     *
     * @param {String} moduleName
     */
    head: function (moduleName) {
      var module = moduleDefinitions[moduleName] = new EasyModule(moduleName);
      module.waiters = [];
      module.dependencies = [];
    },
    /**
     *
     * @param {String} moduleName
     * @param {String|Function} getter
     */
    transform: function (moduleName, getter) {
      EasyGem.schedule.require(function (instance) {
        moduleInstances[moduleName] = instance;
        executeWaiters();
      }, getter);
    },
    /**
     *
     * @param {String} moduleName
     * @param {String} url
     */
    setUrl: function (moduleName, url) {
      urls[moduleName] = url;
      executeWaiters();
    }
  };
  /**
   *
   * @param {Array.<String>} moduleNames
   * @param {Function} callback
   */
  EasyGem.loadModules = function (moduleNames, callback) {
    var waiter = new Waiter(moduleNames, callback);
    if (checkDependencies(moduleNames)) {
      executeWaiter(waiter);
    } else {
      waiters.push(waiter);
      setTimeout(findMissingModules, 3000);
    }
  };
  /**
   *
   * @param {String} moduleName
   * @param {Function} callback
   */
  EasyGem.loadModule = function (moduleName, callback) {
    this.loadModules([moduleName], callback);
  };
  EasyGem.module.transform("jQuery", "jQuery");
  EasyGem.module.transform("jQueryUI", "jQueryUI");


})();