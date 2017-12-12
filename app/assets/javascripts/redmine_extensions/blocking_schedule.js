(function () {
  "use strict";
  /**
   * @callback SchedulePrerequisite
   * @return {boolean}
   */
  /**
   * @typedef {{func:Function,[priority]:number,[pre]:SchedulePrerequisite,[pres]:Array.<SchedulePrerequisite>}} ScheduleTask
   */
  var lateMaxDelay = 3;
  var lateDelay = lateMaxDelay;
  /** @type {Array.<ScheduleTask>} */
  var mainArray = [];
  /** @type {Array.<ScheduleTask>} */
  var lateArray = [];
  /** @type {Array.<(ScheduleTask|null)>} */
  var prerequisiteArray = [];
  var moduleGetters = {
    jquery: function () {
      return window.jQuery;
    },
    jqueryui: function () {
      return window.jQuery && $.fn.widget;
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
      for (var i = 0; i < mainArray.length; i++) {
        mainArray[i].func();
      }
      mainArray = [];
      lateDelay = lateMaxDelay;
    }
    var count2 = executePrerequisites();
    var count3 = 0;
    if (lateArray.length) {
      if (lateDelay === 0) {
        lateArray.sort(sortFunction);
        var limitPriority = lateArray[0].priority - 5;
        for (i = 0; i < lateArray.length; i++) {
          if (lateArray[i].priority <= limitPriority) break;
          lateArray[i].func.call(window);
        }
        if (i === lateArray.length) {
          count3 = lateArray.length;
          lateArray = [];
          lateDelay = lateMaxDelay;
        } else {
          lateArray = lateArray.slice(i);
          count3 = i;
        }
      } else {
        lateDelay--;
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
    var instance;
    var getter;
    var getters;
    var instances;
    for (var i = 0; i < prerequisiteArray.length; i++) {
      if (getter = prerequisiteArray[i].pre) {
        instance = preparePrerequisite(getter);
        if (instance) {
          count++;
          prerequisiteArray[i].func.call(window, instance);
          prerequisiteArray[i] = null;
        }
      } else if (getters = prerequisiteArray[i].pres) {
        instances = [];
        for (var j = 0; j < getters.length; j++) {
          getter = getters[j];
          instance = preparePrerequisite(getter);
          if (!instance) break;
          instances.push(instance);
        }
        if (instances.length !== getters.length) continue;
        count++;
        prerequisiteArray[i].func.apply(window, instances);
        prerequisiteArray[i] = null;
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

  var cycle = function scheduleCycle() {
    tick();
    setTimeout(cycle, 10);
  };
  document.addEventListener("DOMContentLoaded", cycle);
  window.EASY = window.EASY || {};
  /**
   *
   * @type {{out: boolean, late: EASY.schedule.late, require: EASY.schedule.require, main: EASY.schedule.main, define: EASY.schedule.define}}
   */
  EASY.schedule = {
    /**
     * Functions, which should be executed right after "DOMContentLoaded" event
     * @param {Function} func
     * @param {number} [priority]
     */
    main: function (func, priority) {
      mainArray.push({func: func, priority: priority || 0})
    },
    /**
     * Functions, which should wait for [prerequisite] fulfillment
     * After that [func] is executed with return value of [prerequisite] as parameter
     * @param {Function} func
     * @param {...(SchedulePrerequisite|string)} prerequisite
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
        prerequisiteArray.push({func: func, pres: pres})
      } else {
        if (typeof prerequisite === "string") {
          prerequisite = prerequisite.toLocaleLowerCase();
        }
        prerequisiteArray.push({func: func, pre: prerequisite})
      }
    },
    /**
     * Functions, which should be executed after several render loops after "DOMContentLoaded" event
     * each 5 levels of priority increase delay by one stack
     * @param {Function} func
     * @param {number} [priority]
     */
    late: function (func, priority) {
      lateArray.push({func: func, priority: priority || 0})
    },
    /**
     * Define module, which will be loaded by [require] function with [name] argument
     * Only one instance will be created
     * @param {string} name
     * @param {Function} getter
     */
    define: function (name, getter) {
      moduleGetters[name.toLocaleLowerCase()] = getter;
    }
  };
  EASY.test = EASY.test || {};
  EASY.test.schedule = {
    setOut: function (state) {
      writeOut=state;
    },
    isLoaded:function () {
      if(mainArray.length>0) return false;
      if(prerequisiteArray.length>0) return false;
      return lateArray.length <= 0;
    }
  };
})();

