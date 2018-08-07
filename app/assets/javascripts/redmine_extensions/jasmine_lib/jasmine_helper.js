(function () {
  var getQueryString = function () {
    var query_string = {};
    var query = window.location.search.substring(1);
    var vars = query.split("&");
    for (var i = 0; i < vars.length; i++) {
      var pair = vars[i].split("=");
      // If first entry with this name
      if (typeof query_string[pair[0]] === "undefined") {
        query_string[pair[0]] = decodeURIComponent(pair[1]);
        // If second entry with this name
      } else if (typeof query_string[pair[0]] === "string") {
        query_string[pair[0]] = [query_string[pair[0]], decodeURIComponent(pair[1])];
        // If third or later entry with this name
      } else {
        query_string[pair[0]].push(decodeURIComponent(pair[1]));
      }
    }
    return query_string;
  };
  var setQueryTestNames = function () {
    var params = getQueryString();
    var requestedTests = params["jasmine"] || params["jasmine[]"] || params["jasmine%5B%5D"];
    if (requestedTests === "true") return;
    var names = data.tags;
    if (typeof requestedTests === "string") {
      names[requestedTests] = true;
    } else if (requestedTests instanceof Array) {
      for (var i = 0; i < requestedTests.length; i++) {
        var name = requestedTests[i];
        names[name] = true;
      }
    } else {
      throw "Wrong type of jasmine value - \"" + requestedTests + "\" is not true|string|Array.<String>";
    }
  };

  function isDescendantOrSame(parent, child) {
    while (child != null) {
      if (child === parent) {
        return true;
      }
      child = child.parentNode;
    }
    return false;
  }

  function notifyOfResult() {
    EasyGem.schedule.require(function () {
      var fail = window.jsApiReporter.specs().some(function (spec) {
        return spec.failedExpectations.length;
      });
      var logo = document.getElementById("logo") || document.getElementsByTagName("h1")[0];
      logo.classList.add("logo-jasmine");
      logo.classList.add("logo-jasmine--" + (fail ? "fail" : "pass"));
      var link = document.createElement('link');
      link.rel = 'shortcut icon';
      if (fail) {
        link.href = "data:image/png;base64,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";
      } else {
        link.href = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAABmJLR0QA/wD/AP+gvaeTAAAF6UlEQVRYw82Wa2wUVRTHf3dmZ3dnu7ul7ba0hZW29AFqUx8US6G2CuoXE1ASSYhGRQnKF+MDPqiJEI2KT6IfiMQ3Ro1RiYoaFSlF8UGLTyzQ7nZb2tV2Q1tkt+22uzvjh5mVblt0C0Y9yeQ/98695/E/5565ggmyX7/foiEl6jav082pbBMvm4DFJibXdZi4x8S9Jp5IMbBpVsrQMtGBxZtvj/MvijjlWTD5Jpm4zMSNAGgsMnc4ACQpVZGW5EFnyFz3pTmzZQIj+ngmJqj590VMEflNpp9bAGwW4QFY5LUCsLTYwLIcI3vNwRgA278zAi9wygD4B4xMJjR6TUv3mPpfH8/Ef87A+CJcZvr1KIDHIXkAHmhwAXBjlQMAl02kKNDN3O9qNyJ//dosAHYeiQKw9etIPkBkTH/cZKLH3Nr0v2Egec43AqiKyAV4eKkbgLUXG5H3DWmG212jAFxRYjMCMgkZixtUuE2GNpvMORRj/EDjyQKAmMYG0973E1PwD4k+rdUWkp1NowbgqlIjshuqVAACgwkAbv3ghMFExBjX3uwxGJAMZkqUCLGyEHcN/kg8ZueRjCI8Wg7rq1VA8KnfYG5vx2gdABJLzooBDY2IFKYjK0hr6CCfz20FDfIDRjFuHXRRYM1mhttJVXE5ut2LiCqnZ0DIZAAsr7ADYLcYuXvmQASAPe1GVc/LV3DZE3TLfezq2MPHfUcpOvcS7pxzPSvVQoplB07Jwm/6CN8nfqdH6eOtg58wVKhTwxXsDXjdpu36M2LAIukMVfSx/dAeNLvC2tpbuEkpQpB6PN1CoUJyA166L57PHZEfaGp+H+ZdAG21oAuTAd34qyWrtTTb8Gk4ZhTTN91Gp0vqV/KGaRv7mBkV5dyaeyVzcf2t014yeNe5mE2LM/m5cQdSiYrmv6jYKIVpiFvWOZbZBKqStvHxssl6PsurV6LlfgGFgZlJB3SmODtCGI8sGY9TwFBVPxHtCFuqrpm28aS8nb0AMacKZu2bh6ynz0ClPU7C/gNq2ULWO0rOyDiABYnnz1kESsjFzM5cCYEfgX84rjMc12kfiNM+EEe1CFSLoKHISkORlewZo6B1sMZTPqngTidtWpin2Eczx1PmV6vngKpG8bTa02YglBcBOcq1toK0jd8R2MnBr3aze+jblG92IVNaVR9B7c23AI0AeoI1ADsPR50Aq84zOuH66gwAfjoCeb9LFFsyJhl7NtZOTtzOatULwNFEmBf6PsDV68OVW8jVjtrJKbU5oj5bv5J2H5CiRoNyCjllfme8hze+eoVvEhKxmjXU2HK4zvcuFcf95OUVsq50FZUia5K+TKHIELfJNNzdC3QiWIjgWNeJRKl/MMEMVXDwtxhLS+w4rRKVBScJhH6ixruQHGH7U9FsSeXYLCsi6OfQ8V/o0bqx9QUoyCtkXdnUxgGekQ77O7t+DqddA/ZoppEK7WTKvAuF+5RayhcuIzY2SjDYSV5eIWvLVnE+WafV1xhuH0Gny8Kpe/tjAKNx/QKATY3hfIATUaNF3LYgC48ti4DcC8ye5MTT6mKeq5c50tbK2tLr/tK4Tw+P0HJgLrLYkXYNCAR17gtpbPmM7gXz8ZJajC4U7mQJI+U1OFH+Utc98e+OIQk7FunD8bfi5OFeDYDOEwCyIB/g3JkKmjJCYu7LeC+6nE/dS9L1PUVa6B+obtowREJ7lS8evn9a/wIpplIZW4a/+SPujR6atvGgPjJW7dvaCfRidTw5PmqmYOJSEzeajNSZ6GLefshuYXn1St7OXoAljY7eQv9AtW9rJ909LhSxgrqXWuFMb8VttRCq473md1AOv8mLwwGiemLKpT49PLIi1nS0umnDEMFgAkWs4POHWidGe0pOMZGU5A0mmfR6E4spDMxk1r75KCEnqhotraqPVNoc0UyhyF2W8EBjuN2odknE0PTXsDqepG7b4HjlZ3cr/rW4j96iEPlduXh+sfn2H8j32foViNsQY6CLEILXUKRd7H7wV2PTthQVfwBOj/OTmN6yuQAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAxOC0wNi0yMVQwODozMTo0NS0wNzowMJVtVyEAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMTgtMDYtMjFUMDg6MzE6NDUtMDc6MDDkMO+dAAAAAElFTkSuQmCC";
      }
      Array.prototype.slice.call(document.querySelectorAll("[type='image/x-icon']")).forEach(function (link) {
        link.parentElement.removeChild(link);
      });
      document.head.appendChild(link);
    }, function () {
      return window.jsApiReporter.finished
    });
  }

  /**
   *
   * @param {Element} element
   * @return {string}
   */
  function identifyElement(element) {
    var result = "null";
    var first = true;
    var itemString;
    while (element) {
      if (element.id) {
        return "#" + element.id + (first ? "" : " > " + result);
      }
      var elClasses = element.className.trim().replace(/\s+/g, ".");
      if (elClasses) elClasses = "." + elClasses;
      itemString = element.tagName.toLowerCase() + elClasses;
      if (first) {
        first = false;
        result = itemString;
      } else {
        result = itemString + " > " + result;
      }
      element = element.parentElement;
    }
    return result;
  }

  var data = {
    _locks: [],
    _timeout: null,
    tags: {},
    topMenuHeight: 60
  };
  var start = function () {
    if (new Date() - data._timeout > 5000) {
      throw "JasmineHelper timeout";
    }
    if (data._locks.length) {
      setTimeout(start, 400);
      return;
    }
    notifyOfResult();
    jasmine.jasmineStart();
  };
  window.jasmineHelper = {
    data: data,
    /**
     * prevent execution of Jasmine until [name] lock have been unlocked
     * @param {String} name
     */
    lock: function (name) {
      if (data._locks.indexOf(name) === -1) {
        data._locks.push(name);
      }
    },
    /**
     * unlock [name] lock, so execution of Jasmine can proceed
     * @param {String} name
     */
    unlock: function (name) {
      var index = data._locks.indexOf(name);
      if (index !== -1) {
        data._locks.splice(index, 1);
      }
    },
    /**
     * unlock [name] lock if [prerequisite] is fulfilled
     * @param {String} name
     * @param {Function} prerequisite
     */
    unlockOnPass: function (name, prerequisite) {
      EasyGem.schedule.require(function () {
        jasmineHelper.unlock(name);
      }, prerequisite);
    },
    parseResult: function () {
      var specs = window.jsApiReporter.specs();
      var shortReport = "";
      var report = "";
      var allPassed = true;
      var result = "";
      for (var i = 0; i < specs.length; i++) {
        var spec = specs[i];
        if (spec.status === "passed") {
          shortReport += ".";
        } else if (spec.status === "pending") {
          shortReport += "O";
        } else {
          allPassed = false;
          shortReport += "X";
          report += "__TEST " + spec.fullName + "______\n";
          for (var j = 0; j < spec.failedExpectations.length; j++) {
            var fail = spec.failedExpectations[j];
            var split = fail.stack.split("\n");
            result += window.location + "\n";
            report += "   " + fail.message + "\n";
            for (var k = 1; k < split.length; k++) {
              if (split[k].indexOf("/jasmine_lib/") > -1) continue;
              report += split[k] + "\n";
            }
          }
        }
      }
      if (allPassed) {
        return "success";
      }
      result += " RESULTS: " + shortReport + "\n" + report;
      //$("#content").text(result.replace("\n", "<br>"));
      return result;
    },
    /**
     * Create mouseEvent of [type] at client position, so it can be triggered by method dispatchEvent(element)
     * @param {String} type
     * @param {int} pageX
     * @param {int} pageY
     * @param {{ctrlKey?:boolean,metaKey?:boolean,altKey?:boolean,shiftKey?:boolean,button?:int,bubble?:boolean,detail?:int,screenX?:int,screenY?:int}} [options]
     * @return {{dispatchEvent:Function}}
     */
    mouseEvent: function (type, pageX, pageY, options) {
      var evt;
      options = options || {};
      EasyGem.extend(options, {
        bubbles: true,
        cancelable: (type !== "mousemove"),
        view: window,
        clientX: pageX - document.body.scrollLeft - document.documentElement.scrollLeft,
        clientY: pageY - document.body.scrollTop - document.documentElement.scrollTop
      });
      if (window.MouseEvent) {
        evt = new MouseEvent(type, options);
      } else if (typeof(document.createEvent) === "function") {
        evt = document.createEvent("MouseEvents");
        evt.initMouseEvent(type,
            options.bubbles, options.cancelable, options.view, options.detail,
            options.screenX, options.screenY, options.clientX, options.clientY,
            options.ctrlKey, options.altKey, options.shiftKey, options.metaKey,
            options.button, document.body.parentNode);
      }
      evt.dispatchEvent = function (el) {
        if (el.dispatchEvent) {
          el.dispatchEvent(this);
        } else if (el.fireEvent) {
          el.fireEvent('on' + type, this);
        }
        return this;
      };
      return evt;
    },
    /**
     * Triggers mouseEvent of [type] at the center of [element]
     * @param {string|Element|jQuery} element - can be HTMLElement, selector or jQuery element
     * @param {string} type
     * @param {{ctrlKey?:boolean,metaKey?:boolean,altKey?:boolean,shiftKey?:boolean,button?:int,bubble?:boolean,detail?:int,screenX?:int,screenY?:int}} [options]
     */
    mouseEventOn: function (element, type, options) {
      if (typeof element === "string") {
        element = document.querySelector(element);
      } else if (element instanceof window.jQuery) {
        element = element[0];
      }
      if (!element) throw new Error("missing element");
      element.scrollIntoView();
      var box = element.getBoundingClientRect();
      if (box.top < data.topMenuHeight) {
        window.scrollBy({top: -data.topMenuHeight});
        box = element.getBoundingClientRect();
      }
      var pointX = (box.left + box.right) / 2;
      var pointY = (box.top + box.bottom) / 2;
      var target = document.elementFromPoint(pointX, pointY);
      if (!isDescendantOrSame(element, target)) {
        throw new Error(identifyElement(element) + " is covered by " + identifyElement(target) + ", can't be clicked");
      }
      return this.mouseEvent(type, pointX, pointY, options).dispatchEvent(element);
    },
    /**
     * Trigger click mouseEvent on [element]
     * @param {string|Element|jQuery} element - can be HTMLElement, selector or jQuery element
     * @param {{ctrlKey?:boolean,metaKey?:boolean,altKey?:boolean,shiftKey?:boolean,button?:int,bubble?:boolean,detail?:int,screenX?:int,screenY?:int}} [options]
     */
    clickOn: function (element, options) {
      return this.mouseEventOn(element, "click", options);
    },
    hasTag: function (tag) {
      return data.tags[tag];
    },
    initPageMatchers: function () {
      jasmine.addMatchers(pageMatchers);
    }
  };
  setQueryTestNames();

  var pageMatchers = {
    toExistsOnPage: function (/*utils, customEqualityTesters*/) {
      return {
        compare: function (selector) {
          var pass = $(selector).length;
          if (pass) {
            return {pass: true, message: "Expected " + selector + " not to be present on page"};
          }
          return {pass: false, message: "Expected " + selector + " to be present on page"};
        }
      };
    },
    toExistsTimes: function (/*utils, customEqualityTesters*/) {
      return {
        compare: function (selector, expected) {
          var count = $(selector).length;
          var pass = count === expected;
          if (pass) {
            return {pass: true, message: "Expected " + selector + " not to be present on page " + expected + "-times"};
          }
          return {
            pass: false,
            message: "Expected " + selector + " to be present on page " + expected + "-times, not " + count + "-times"
          };
        }
      };
    }
  };

  EasyGem.schedule.late(function () {
    data._timeout = new Date();
    start();
  }, -100);
})();
