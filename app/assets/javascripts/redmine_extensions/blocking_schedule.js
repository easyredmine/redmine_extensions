(function () {
  "use strict";
  /**
   * @typedef {Function} SchedulePrerequisite
   * @return {boolean}
   */
  /**
   * @typedef {{func:Function,[priority]:number,[pre]:SchedulePrerequisite}} ScheduleTask
   */
  var lateMaxDelay = 3;
  var lateDelay = lateMaxDelay;
  /** @type {Array.<ScheduleTask>} */
  var mainArray = [];
  /** @type {Array.<ScheduleTask>} */
  var lateArray = [];
  /** @type {Array.<ScheduleTask|null>} */
  var prerequisiteArray = [];

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
        // console.log(lateArray.map(function (p1) {
        //   return p1.priority
        // }));
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
    if (EASY.schedule.out && (count1 || count2 || count3)) {
      console.log("EE: " + count1 + " REQ: " + count2 + " LATE: " + count3);
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
      if (prerequisiteArray[i].pre()) {
        count++;
        prerequisiteArray[i].func.call(window);
        prerequisiteArray[i] = null;
      }
    }
    if (count) {
      prerequisiteArray = prerequisiteArray.filter(isNotNull);
      count += executePrerequisites();
    }
    return count;
  };

  var cycle = function scheduleCycle() {
    tick();
    window.requestAnimationFrame(cycle);
  };
  document.addEventListener("DOMContentLoaded", cycle);
  window.EASY = window.EASY || {};
  /**
   *
   * @type {{out: boolean, late: EASY.schedule.late, require: EASY.schedule.require, main: EASY.schedule.main}}
   */
  EASY.schedule = {
    out: false,
    /**
     * Functions, which should be executed right after "DOMContentLoaded" event
     * @param {Function} func
     * @param {number} [priority]
     */
    main: function (func, priority) {
      mainArray.push({func: func, priority: priority || 0})
    },
    /**
     * Functions, which should wait for prerequisite fulfillment
     * @param {Function} func
     * @param {SchedulePrerequisite} prerequisite
     */
    require: function (func, prerequisite) {
      prerequisiteArray.push({func: func, pre: prerequisite})
    },
    /**
     * Functions, which should be executed after several render loops after "DOMContentLoaded" event
     * @param {Function} func
     * @param {number} [priority]
     */
    late: function (func, priority) {
      lateArray.push({func: func, priority: priority || 0})
    }
  };
})();

