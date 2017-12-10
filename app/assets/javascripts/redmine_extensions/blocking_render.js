(function () {
  /**
   * @type {Array.<{body:Function,ctx:Object}>}
   */
  var renderQueue = [];
  /**
   * @type {Array.<{body:Function,ctx:Object}>}
   */
  var afterRenderQueue = [];
  /**
   * @param {Function} body
   * @param {Object} [context]
   */
  EASY.render = function (body, context) {
    renderQueue.push({body: body, ctx: context});
  };
  EASY.render.after = function (body, context) {
    renderQueue.push({body: body, ctx: context});
  };
  EASY.schedule.main(function () {
    requestAnimationFrame(function (time) {
      if(renderQueue.length){
        for (var i = 0; i < renderQueue.length; i++) {
          var pack = renderQueue[i];
          pack.body.apply([pack.ctx, time]);
        }
        renderQueue = [];
      }
      if(afterRenderQueue.length){
        for (i = 0; i < afterRenderQueue.length; i++) {
          pack = afterRenderQueue[i];
          pack.body.apply([pack.ctx, time]);
        }
        afterRenderQueue = [];
      }
    });
  });
})();