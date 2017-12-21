EasyGem.dynamic = {
  jsTag: function (src) {
    var jsScript = document.createElement("script");
    jsScript.setAttribute("src", src);
    jsScript.setAttribute("defer", "true");
    document.head.appendChild(jsScript);
  },
  cssTag: function (src) {
    var link = document.createElement('link');
    link.rel = "stylesheet";
    link.type = "text/css";
    link.href = src;
    link.media = "all";
    document.head.appendChild(link);
  },
  jsTags: function (array, plugin) {
    for (var i = 0; i < array.length; i++) {
      this.jsTag(array[i], plugin);
    }
  },
  cssTags: function (array, plugin) {
    for (var i = 0; i < array.length; i++) {
      this.cssTag(array[i], plugin);
    }
  }
};