(function () {
  var alreadyLoaded = {};
  EasyGem.dynamic = {
    _alreadyLoaded: alreadyLoaded,
    /**
     * Append Javascript <script> tag to page
     * @example
     * EasyGem.dynamic.jsTag("/plugin_assets/my_plugin/javascripts/counter.js");
     * EasyGem.schedule.require(function(counter){
     *   setInterval(counter.count(), 1000);
     * }, function(){
     *   return window.utils.counter;
     * })
     * @param {String} src - absolute path to requested file
     */
    jsTag: function (src) {
      if (alreadyLoaded[src]) return;
      alreadyLoaded[src] = true;
      var jsScript = document.createElement("script");
      jsScript.setAttribute("src", src);
      jsScript.setAttribute("defer", "true");
      document.head.appendChild(jsScript);
    },
    /**
     * Append CSS <link> tag to page
     * @param {String} src - absolute path to requested file
     */
    cssTag: function (src) {
      if (alreadyLoaded[src]) return;
      alreadyLoaded[src] = true;
      var link = document.createElement('link');
      link.rel = "stylesheet";
      link.type = "text/css";
      link.href = src;
      link.media = "all";
      document.head.appendChild(link);
    },
    /**
     * Append JS or CSS file, depends on suffix
     * @param {String} src
     */
    sourceTag: function(src){
      var end=src.substring(src.length-3);
      if(end===".js"){
        this.jsTag(src);
      }else if(end === "css"){
        this.cssTag(src);
      }
    },
    /**
     * Load multiple JS files into page
     * @param {Array.<String>} array
     */
    jsTags: function (array) {
      array.forEach(this.jsTag);
    },
    /**
     * Load multiple CSS files into page
     * @param {Array.<String>} array
     */
    cssTags: function (array) {
      array.forEach(this.cssTag);
    },
    /**
     * Order file from server and when the file is loaded, execute [callback] with [name] as first argument
     * It is necessary to define module with [name] in the file = EasyGem.schedule.define(name,function(){...});
     * @param {String} url
     * @param {Function} callback
     * @param {String} name
     * @param {String...} [prerequisites]
     */
    loadAndRun: function (url, callback, name, prerequisites) {
      this.jsTag(url);
      var args = Array.prototype.slice.call(arguments, 1);
      EasyGem.schedule.require.apply(window, args);
    }
  };
})();
