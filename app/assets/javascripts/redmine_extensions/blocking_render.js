(function () {
  /**
   * @callback RenderFunction
   */
  // noinspection JSMismatchedCollectionQueryUpdate
  /**
   * @type {Array.<{body:RenderFunction,ctx:Object}>}
   */
  var readQueue = [];
  // noinspection JSMismatchedCollectionQueryUpdate
  /**
   * @type {Array.<{body:RenderFunction,ctx:Object,value:*}>}
   */
  var renderQueue = [];
  var renderPhase = false;
  var lastTime = 0.0;
  /**
   * Wrapper for safe execution of [body] function only in read phase to prevent force-redraws.
   * @example
   * // fill storage with values from DOM
   * var storage = {};
   * EasyGem.read(function(){
   *   this.offset = $element.offset();
   *   this.scrollTop = $(window).scrollTop();
   * }, storage);
   * @param {RenderFunction} body
   * @param {Object} [context]
   */
  EasyGem.read = function (body, context) {
    if (renderPhase) {
      readQueue.push({body: body, ctx: context});
    } else {
      body.call(context);
    }
  };
  /**
   * Wrapper for safe execution of [body] function only in render phase to prevent force-redraws.
   * @example
   * var left = $element.css("left");
   * EasyGem.render(function(){
   *   $element.css({left: (left + 5) + "px"});
   * });
   * @param {RenderFunction} body - obtain execution time as first parameter
   * @param {Object} [context]
   */
  EasyGem.render = function (body, context) {
    if (renderPhase) {
      body.call(context, lastTime);
    } else {
      renderQueue.push({body: body, ctx: context});
    }
  };
  /**
   * Complex and most-safe wrapper for DOM-manipulation code
   * Execute [read] and [render] function only in proper phases.
   * @example
   * // prevents layout thrashing
   * $table.find("td.first_column").each(function() {
   *   EasyGem.readAndRender(function() {
   *     return this.width();
   *   }, function(width, time) {
   *     this.next().width(width);
   *   }, $(this));
   * });
   * @param {RenderFunction} read
   * @param {RenderFunction} render - function(readResult, time) callback
   * @param {Object} [context]
   */
  EasyGem.readAndRender = function (read, render, context) {
    if (renderPhase) {
      readQueue.push({
        body: function () {
          var value = read.call(context);
          renderQueue.push({body: render, ctx: context, value: value});
        }, ctx: context
      });
    } else {
      var value = read.call(context);
      renderQueue.push({body: render, ctx: context, value: value});
    }
  };
  EasyGem.schedule.main(function () {
    var loop = function (time) {
      renderPhase = true;
      lastTime=time;

      setTimeout(function () {
        renderPhase = false;
        if (readQueue.length) {
          var queue = readQueue;
          readQueue = [];
          for (i = 0; i < queue.length; i++) {
            var pack = queue[i];
            pack.body.call(pack.ctx);
          }
        }
      }, 0);
      if (renderQueue.length) {
        var queue = renderQueue;
        renderQueue = [];
        for (var i = 0; i < queue.length; i++) {
          var pack = queue[i];
          pack.body.call(pack.ctx, pack.value, time);
        }
        renderQueue = [];
      }
      requestAnimationFrame(loop);
    };
    requestAnimationFrame(loop);
  });
  EasyGem.test.render = {
    getPhase: function () {
      return renderPhase ? "render" : "read";
    }
    // ,
    // test1: function () {
    //   console.log("Phase "+this.getPhase());
    //   EasyGem.render(function (time) {
    //     console.assert(this.getPhase() === "render", "Phase should be render, not ", this.getPhase());
    //     console.assert(typeof time === "number", "Time ", time, " should be number, not ", typeof time);
    //     console.log("render done");
    //   }, this);
    //   EasyGem.read(function () {
    //     console.assert(this.getPhase() === "read", "Phase should be read, not ", this.getPhase());
    //     console.log("read done");
    //   }, this);
    //   EasyGem.readAndRender(function () {
    //     console.assert(this.getPhase() === "read", "Phase should be read, not ", this.getPhase());
    //     return 562;
    //   }, function (time, value) {
    //     console.assert(this.getPhase() === "render", "Phase should be render, not ", this.getPhase());
    //     console.assert(value === 562, "Value should be 562, not ", value);
    //     console.log("readAndRender done");
    //   }, this)
    // }
  };
})();