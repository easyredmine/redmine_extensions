EasyGem.schedule.require(function (jQuery) {
  var running,
      animate = function (elem) {
        if (running) {
          window.requestAnimationFrame(animate, elem);
          jQuery.fx.tick();
        }
      };
  jQuery.fx.timer = function (timer) {
    if (timer() && jQuery.timers.push(timer) && !running) {
      running = true;
      animate(timer.elem);
    }
  };

  jQuery.fx.stop = function () {
    running = false;
  };
},'jQuery');

