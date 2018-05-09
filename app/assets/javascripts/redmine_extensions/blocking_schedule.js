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
      var pack = prerequisiteArray[i];
      if (!pack) {
        count++;
        continue;
      }
      if (pack.pre) {
        var instance = preparePrerequisite(pack.pre);
        if (instance) {
          count++;
          prerequisiteArray[i] = null;
          pack.func.call(window, instance);
        }
      } else {
        var instances = prepareMorePrerequisites(pack.pres);
        if (instances) {
          count++;
          prerequisiteArray[i] = null;
          pack.func.apply(window, instances);
        }
      }
    }
    if (count) {
      prerequisiteArray = prerequisiteArray.filter(isNotNull);
      count += executePrerequisites();
    }
    return count;
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
  var prepareMorePrerequisites = function (getters) {
    var instance, instances = [];
    for (var j = 0; j < getters.length; j++) {
      instance = preparePrerequisite(getters[j]);
      if (!instance) return null;
      instances.push(instance);
    }
    return instances;
  };

  var cycle = function scheduleCycle() {
    setTimeout(cycle, 30);
    tick();
  };
  document.addEventListener("DOMContentLoaded", cycle);
  /**
   *
   * @type {{late: EasyGem.schedule.late, require: EasyGem.schedule.require, main: EasyGem.schedule.main, define: EasyGem.schedule.define}}
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
            pres.push(arguments[i].toLowerCase());
          } else {
            pres.push(arguments[i]);
          }
        }
        var instances = prepareMorePrerequisites(pres);
        if (instances) {
          func.apply(window, instances);
        } else {
          prerequisiteArray.push({func: func, pres: pres});
        }
      } else {
        if (typeof prerequisite === "string") {
          prerequisite = prerequisite.toLowerCase();
        }
        var instance = preparePrerequisite(prerequisite);
        if (instance) {
          func.call(window, instance);
        } else {
          prerequisiteArray.push({func: func, pre: prerequisite});
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
     * @param {...(SchedulePrerequisite|string)} [prerequisite] - more than one prerequisite can be specified here
     *                                           as rest parameters. Function or String are accepted. If String is used,
     *                                           predefined getter from [moduleGetters] or getter defined by [define]
     *                                           are called.
     */
    define: function (name, getter, prerequisite) {
      if (prerequisite) {
        this.require.apply(this, [function () {
          moduleGetters[name.toLowerCase()] = getter;
        }].concat(Array.prototype.slice.call(arguments, 2)));
      } else {
        moduleGetters[name.toLowerCase()] = getter;
      }
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

