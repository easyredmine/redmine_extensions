EasyGem.dynamic = {
  /**
   * Append Javascript <script> tag to page
   * @param {String} src - absolute path to requested file
   */
  jsTag: function (src) {
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
    var link = document.createElement('link');
    link.rel = "stylesheet";
    link.type = "text/css";
    link.href = src;
    link.media = "all";
    document.head.appendChild(link);
  },
  /**
   * Load multiple JS files into page
   * @param {Array.<String>} array
   */
  jsTags: function (array) {
    for (var i = 0; i < array.length; i++) {
      this.jsTag(array[i]);
    }
  },
  /**
   * Load multiple CSS files into page
   * @param {Array.<String>} array
   */
  cssTags: function (array) {
    for (var i = 0; i < array.length; i++) {
      this.cssTag(array[i]);
    }
  }
};