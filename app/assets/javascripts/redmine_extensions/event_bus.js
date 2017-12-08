/**
 * Created by hosekp on 11/10/16.
 */
(function () {
  /**
   * @method fire
   * @method on
   * @method of
   * @constructor
   */
  function EventBus() {
    this.registeredMap = {};
  }

  /**
   * send event to all of the listeners of specified event
   * @param {String} event
   * @param {...any}
   */
  EventBus.prototype.fire = function (event) {
    var proFunctions = this.registeredMap[event];
    if (!proFunctions) return;
    var slicedArgs = Array.prototype.slice.call(arguments, 1);
    for (var i = 0; i < proFunctions.length; i++) {
      proFunctions[i].apply(this, slicedArgs);
    }
  };
  /**
   * Register listener of specified event
   * @param {String} event
   * @param {Function} func
   */
  EventBus.prototype.on = function (event, func) {
    var eventList = this.registeredMap[event];
    if (!eventList) this.registeredMap[event] = eventList = [];
    for (var i = 0; i < eventList.length; i++) {
      if (eventList[i] === func) {
        return;
      }
    }
    eventList.push(func);
  };
  /**
   *
   * @param {String} event
   * @param {Function} func
   */
  EventBus.prototype.off = function (event, func) {
    var eventList = this.registeredMap[event];
    if (!eventList) return;
    for (var i = 0; i < eventList.length; i++) {
      if (eventList[i] === func) {
        eventList.splice(i, 1);
        return;
      }
    }
  };
  window.EASY = window.EASY || {};
  EASY.eventBusFactory = EventBus;
  EASY.eventBus = new EventBus();
})();