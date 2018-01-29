(function () {
  "use strict";
  /**
   * @callback SchedulePrerequisite
   * @return {boolean}
   */
  /**
   * @typedef {{func:Function,[priority]:number,[pre]:SchedulePrerequisite,[pres]:Array.<SchedulePrerequisite>}} ScheduleTask
   */
  // noinspection JSMismatchedCollectionQueryUpdate
  /** @type {Array.<ScheduleTask>} */
  var mainArray = [];
  /** @type {Array.<ScheduleTask>} */
  var lateArray = [];
  /** @type {Array.<?ScheduleTask>} */
  var prerequisiteArray = [];
  /**
   * Predefined getters for [require] function. Just specify the name of the module
   * @type {{jquery: jquery, jqueryui: jqueryui, c3: c3, ckeditor: ckeditor}}
   */
  var moduleGetters = {
    jquery: function () {
      return window.jQuery;
    },
    jqueryui: function () {
      return window.jQuery && jQuery.Widget;
    },
    c3: function () {
      return window.c3;
    },
    ckeditor: function () {
      return window.CKEDITOR;
    }
  };
  var moduleInstances = {};
  var writeOut = false;

  /** @param {ScheduleTask} a
   * @param {ScheduleTask} b
   */
  var sortFunction = function (a, b) {
    return b.priority - a.priority;
  };

  var tick = function () {
    var count1 = 0;
    if (mainArray.length > 0) {
      count1 = mainArray.length;
      mainArray.sort(sortFunction);
      var queue = mainArray;
      mainArray = [];
      for (var i = 0; i < queue.length; i++) {
        queue[i].func();
      }
    }
    var count2 = executePrerequisites();
    var count3 = 0;
    if (lateArray.length && count1 === 0 && count2 === 0) {
      lateArray.sort(sortFunction);
      var limitPriority = lateArray[0].priority - 5;
      for (i = 0; i < lateArray.length; i++) {
        if (lateArray[i].priority <= limitPriority) break;
      }
      count3 = i;
      if (i === lateArray.length) {
        queue = lateArray;
        lateArray = [];
      } else {
        queue = lateArray.slice(0, i);
        lateArray = lateArray.slice(i);
      }
      for (i = 0; i < queue.length; i++) {
        if (queue[i].priority <= limitPriority) break;
        queue[i].func.call(window);
      }
    }
    if (writeOut && (count1 || count2 || count3)) {
      console.log("MAIN: " + count1 + " REQ: " + count2 + " LATE: " + count3);
    }
  };
  var isNotNull = function (a) {
    return a !== null;
  };
  /** @return {number} */
  var executePrerequisites = function () {
    if (prerequisiteArray.length === 0) return 0;
    var count = 0;
    for (var i = 0; i < prerequisiteArray.length; i++) {
      if (executeOnePrerequisite(prerequisiteArray[i])) {
        count++;
        prerequisiteArray[i] = null;
      }
    }
    if (count) {
      prerequisiteArray = prerequisiteArray.filter(isNotNull);
      count += executePrerequisites();
    }
    return count;
  };
  var executeOnePrerequisite = function (pack) {
    var getter, getters, instance, instances;
    if (getter = pack.pre) {
      instance = preparePrerequisite(getter);
      if (instance) {
        pack.func.call(window, instance);
        return true;
      }
      return false;
    } else if (getters = pack.pres) {
      instances = [];
      for (var j = 0; j < getters.length; j++) {
        getter = getters[j];
        instance = preparePrerequisite(getter);
        if (!instance) break;
        instances.push(instance);
      }
      if (instances.length !== getters.length) return false;
      pack.func.apply(window, instances);
      return true;
    }
  };
  /**
   * @param {(Function|string)} getter
   * @return {(Object|null)}
   */
  var preparePrerequisite = function (getter) {
    var instance;
    if (typeof getter === "string") {
      if (moduleInstances[getter]) {
        return moduleInstances[getter];
      } else if (moduleGetters[getter]) {
        instance = moduleGetters[getter]();
        if (instance) {
          moduleInstances[getter] = instance;
        }
        return instance;
      }
      return null;
    } else {
      return getter();
    }
  };

  var cycle = function scheduleCycle() {
    setTimeout(cycle, 30);
    tick();
  };
  document.addEventListener("DOMContentLoaded", cycle);
  /**
   *
   * @type {{out: boolean, late: EASY.schedule.late, require: EASY.schedule.require, main: EASY.schedule.main, define: EASY.schedule.define}}
   */
  EasyGem.schedule = {
    /**
     * Functions, which should be executed right after "DOMContentLoaded" event.
     * @param {Function} func
     * @param {number} [priority=0] - Greater the priority, sooner [func] are called. Each 5 priority delays execution
     *                              by 30ms. Also negative values are accepted.
     */
    main: function (func, priority) {
      mainArray.push({func: func, priority: priority || 0})
    },
    /**
     * Functions, which should wait for [prerequisite] fulfillment
     * After that [func] is executed with return value of [prerequisite] as parameter
     * @example
     * // execute function after jQuery and window.logger are present
     * EasyGem.schedule.require(function($,logger){
     *   logger.log($.fn.jquery);
     * },'jQuery',function(){
     *   return window.logger;
     * });
     * @param {Function} func - function which will be called when all prerequisites are met. Results of prerequisites
     *                          are send into [func] as parameters
     * @param {...(SchedulePrerequisite|string)} prerequisite - more than one prerequisite can be specified here
     *                                           as rest parameters. Function or String are accepted. If String is used,
     *                                           predefined getter from [moduleGetters] or getter defined by [define]
     *                                           are called.
     */
    require: function (func, prerequisite) {
      if (arguments.length > 2) {
        var pres = [];
        for (var i = 1; i < arguments.length; i++) {
          if (typeof arguments[i] === "string") {
            pres.push(arguments[i].toLocaleLowerCase());
          } else {
            pres.push(arguments[i]);
          }
        }
        var pack = {func: func, pres: pres};
        if (!executeOnePrerequisite(pack)) {
          prerequisiteArray.push(pack);
        }
      } else {
        if (typeof prerequisite === "string") {
          prerequisite = prerequisite.toLocaleLowerCase();
        }
        pack = {func: func, pre: prerequisite};
        if (!executeOnePrerequisite(pack)) {
          prerequisiteArray.push(pack);
        }
      }
    },
    /**
     * Functions, which should be executed after several loops after "DOMContentLoaded" event.
     * Each 5 levels of priority increase delay by one stack.
     * @param {Function} func
     * @param {number} [priority=0]
     */
    late: function (func, priority) {
      lateArray.push({func: func, priority: priority || 0})
    },
    /**
     * Define module, which will be loaded by [require] function with [name] prerequisite
     * Only one instance will be created and cached also for future use.
     * If no one request the module, getter is never called.
     * @example
     * EasyGem.schedule.define('Counter', function () {
     *   var count = 0;
     *   return function () {
     *     console.log("Count: " + count++);
     *   }
     * });
     * @param {string} name
     * @param {Function} getter - getter or constructor
     */
    define: function (name, getter) {
      moduleGetters[name.toLocaleLowerCase()] = getter;
    }
  };
  EASY.schedule = EasyGem.schedule;
  EasyGem.test.schedule = {
    setOut: function (state) {
      writeOut = state;
    },
    isLoaded: function () {
      if (mainArray.length > 0) return false;
      if (prerequisiteArray.length > 0) return false;
      return lateArray.length <= 0;
    },
    lateIsLoaded: function () {
      return lateArray.length <= 0;
    },
    queueContents: function () {
      var modules = [];
      for (var i = 0; i < prerequisiteArray.length; i++) {
        var prerequisite = prerequisiteArray[i];
        if (typeof prerequisite.pre === "string") {
          modules.push(prerequisite.pre);
        } else if (prerequisite.pres) {
          for (var j = 0; j < prerequisite.pres.length; j++) {
            var pre = prerequisite.pres[j];
            if (typeof pre === "string") {
              modules.push(pre);
            }
          }
        }
      }
      return {main: mainArray.length, late: lateArray, require: prerequisiteArray.length, waitsFor: modules};
    }
  };
})();

