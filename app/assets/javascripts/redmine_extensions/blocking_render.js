(function () {
  /**
   * @type {Array.<{body:Function,ctx:Object}>}
   */
  var renderQueue = [];
  /**
   * @param {Function} body
   * @param {Object} [context]
   */
  EASY.render = function (body, context) {
    renderQueue.push({body: body, ctx: context});
  };
  requestAnimationFrame(function (time) {
    for (var i = 0; i < renderQueue.length; i++) {
      var pack = renderQueue[i];
      pack.body.apply([pack.ctx, time]);
    }
    renderQueue = [];
  });
})();