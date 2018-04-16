(function () {
  "use strict";

  var modules={};
  var waiters=[];
  /**
   * @property {Function} factory
   * @property {String} name
   * @property {Array.<String>} dependencies
   * @constructor
   */
  function Module(moduleName) {
    this.name = moduleName;
    this.fulfilled=false;
    this.submodules=[];
    // this.dependencies = dependencies;
    // this.factory = factory;
  }

  function checkOtherWaiters(moduleName){

  }

  function isDependenciesFulfilled(moduleName){

  }
  function getPrerequisite(moduleName){

  }


  EasyGem.module = {
    urls:{},
    /**
     * Define
     * @param {String} moduleName
     * @param {Array.<String>} prerequisites
     * @param {Function} getter
     */
    module: function (moduleName, prerequisites, getter) {
      var module = modules[moduleName] = new Module(moduleName);
      module.dependencies=prerequisites;
      module.factory=getter;
    },
    /**
     *
     * @param {String} moduleName
     * @param {Array.<String>} prerequisites
     * @param {Function} getter
     */
    modulePart: function (moduleName,prerequisites, getter) {

    },
    /**
     *
     * @param {String} moduleName
     */
    moduleHead:function (moduleName) {

    },
    /**
     *
     * @param {Array.<String>} moduleNames
     * @param {Function} callback
     */
    loadModules:function (moduleNames,callback) {

    },
    /**
     *
     * @param {String} moduleName
     * @param {Function} callback
     */
    loadModule:function (moduleName,callback) {
      this.loadModules([moduleName],callback);
    }



  };


})();