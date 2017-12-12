(function () {
  "use strict";
  return;

  var modules = {};
  var waiters = {};
  var modulesOrdered = {};

  window.EASY = window.EASY || {};
  EASY.modules = {};

  var getMissingModule = function (dependencyNames) {
    for (var i = 0; i < dependencyNames.length; i++) {
      var dependencyName = dependencyNames[i];
      var dependency = modules[dependencyName];
      if (!dependency || !dependency.instance) return dependencyName;
    }
    return null;
  };

  EASY.eventBus.on("moduleReady", function (moduleName) {
    if (waiters[moduleName]) {
      var subWaiters = waiters[moduleName];
      delete waiters[moduleName];
      delete modulesOrdered[moduleName];
      subWaiters.forEach(function (pack) {
        requireTry(pack);
      })
    }
  });


  /**
   * @property {Function} factory
   * @property {String} name
   * @property {Array.<Module>} dependencies
   * @constructor
   */
  function Module(moduleName, dependencies, factory) {
    this.name = moduleName;
    this.dependencies = dependencies;
    this.factory = factory;
    if (modulesOrdered[moduleName]) {
      this.construct();
    }
  }

  Module.prototype.instance = null;
  Module.prototype.factory = function () {
    return {};
  };
  Module.prototype.name = "unnamed";
  Module.prototype.dependencies = [];
  Module.prototype.construct = function (visited) {
    var dependencyInstances;
    visited = visited || [];
    if(visited.indexOf(this.name)>-1){
      throw "Cyclic dependency: " + this.name + " -> " + visited[visited.length - 1] + " -> " + this.name;
    }

    if (this.dependencies) {
      dependencyInstances = [];
      /** @type {Module} */
      var dependency;
      for (var i = 0; i < this.dependencies.length; i++) {
        dependency = this.dependencies[i];
        if (dependency.instance) {
          dependencyInstances.push(dependency.instance);
        } else {
          return dependency.construct(visited.concat([this.name]));
        }
      }
    }
    this.instance = this.factory(dependencyInstances);
    if (this.instance) {
      EASY.eventBus.fire("moduleReady", this.name);
    } else {
      var self = this;
      setTimeout(function () {
        self.construct();
      }, 10);
    }
  };

  var getDependencies = function (dependencyNames) {
    var dependencyInstances = [];
    for (var i = 0; i < dependencyNames.length; i++) {
      var dependencyName = dependencyNames[i];
      var dependency = modules[dependencyName];
      if (!dependency) return null;
      if (!dependency.instance) {
        dependency.construct();
      }
      if (!dependency.instance) {
        return null;
      }
      dependencyInstances.push(dependency.instance);
    }
    return dependencyInstances;
  };
  /**
   * @param {{dependencies:Array.<String>,body:Function,context:Object}} pack
   */
  var requireTry = function (pack) {
    var dependencyInstances = getDependencies(pack.dependencies);
    if (dependencyInstances !== null) {
      return pack.body.apply([pack.context || window].concat(dependencyInstances));
    }
    var missingModule = getMissingModule(pack.dependencies);
    if (missingModule === null) return;
    if (!modules[missingModule]) {
      modulesOrdered[missingModule] = true;
    }

    if (!waiters[missingModule]) {
      waiters[missingModule] = [];
    }
    waiters[missingModule].push(pack);
  };


  //####################################################################################################################

  /**
   * Module constructor. Execute [factory] only if [moduleName] is registered
   * Works also, if EASY.registerModule is called after module definition
   * @param {String} moduleName
   * @param {Array.<String>} dependencies
   * @param {Function} factory
   */
  EASY.modules.module = function easyModule(moduleName, dependencies, factory) {
    modules[moduleName] = new Module(moduleName, dependencies, factory);
  };
  /**
   * @param {String} moduleName
   * @param {Function} getter
   */
  EASY.modules.toModule = function (moduleName, getter) {
    modules[moduleName] = new Module(moduleName, null, getter);
  };
  /**
   * @param {Array.<String>} dependencies
   * @param {Function} body
   * @param {Object} [context]
   */
  EASY.modules.require = function (dependencies, body, context) {
    if (!dependencies || dependencies.length === 0) body.call(context || window);
    requireTry({dependencies: dependencies, body: body, context: context});
  };
  //####################################################################################################################

  EASY.modules.toModule("jQuery", function () {
    return window.jQuery;
  });
  EASY.modules.toModule("$", function () {
    return window.jQuery;
  });
  EASY.modules.toModule("jQueryUI", function () {
    if (window.jQuery && window.jQuery.widget) {
      return window.jQuery;
    }
  });
})();