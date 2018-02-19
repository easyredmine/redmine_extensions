/**
 * Duplication of $.extend(), so whole jQuery dont have to be loaded
 * @param {boolean|Object} deep
 * @param {Object} target
 * @param {Object} [source]
 * @return {Object}
 */
EasyGem.extend = function (deep, target, source) {
  var copyIsArray;
  if (typeof deep !== "boolean") {
    source = target;
    target = deep;
    deep = false;
  }
  if (source === undefined) return target;
  if (typeof target !== "object") {
    target = {};
  }
  for (var name in source) {
    if (!source.hasOwnProperty(name)) continue;
    var trg = target[name];
    var src = source[name];

    // Prevent never-ending loop
    if (trg === src) continue;
    if (deep && src && typeof src === "object") {
      copyIsArray = Array.isArray(src);
      if (copyIsArray) {
        copyIsArray = false;
        var clone = trg && Array.isArray(trg) ? trg : [];

      } else {
        clone = trg && (typeof trg === "object") ? trg : {};
      }

      // Never move original objects, clone them
      target[name] = EasyGem.extend(deep, clone, src);

      // Don't bring in undefined values
    } else if (src !== undefined) {
      target[name] = src;
    }
  }
  return target;
};
EASY.extend = EasyGem.extend;
