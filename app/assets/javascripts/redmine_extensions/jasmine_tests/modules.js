describe("Modules", function () {
  var nameCounter = 0;

  function getName() {
    return "jasmine_test_" + (nameCounter++);
  }

  function defineOptionModule(moduleName, context) {
    EasyGem.module.module(moduleName, function () {
      return function () {
        context.add.apply(context, arguments);
      }
    });
  }

  function defineCallbackModule(moduleName, context) {
    EasyGem.module.module(moduleName, function () {
      return {
        add: function () {
          context.add.apply(context, arguments);
        }
      };
    });
  }

  function resolveModules() {
    EasyGem.module.setUrl("", null);
  }

  beforeEach(function () {
    this.counter = 1;
    var self = this;
    this.count = function () {
      self.counter++;
    };
    this.add = function (add) {
      for (var i = 0; i < arguments.length; i++) {
        self.counter += arguments[i];
      }
    };
  });
  describe("simple", function () {
    it("works with option", function () {
      var moduleName = getName();
      defineOptionModule(moduleName, this);
      expect(this.counter).toEqual(1);
      EasyGem.loadModule(moduleName, 5);
      expect(this.counter).toEqual(6);
    });
    it("works with callback", function () {
      var moduleName = getName();
      defineCallbackModule(moduleName, this);
      expect(this.counter).toEqual(1);
      EasyGem.loadModule(moduleName, function (module) {
        module.add(5);
      });
      expect(this.counter).toEqual(6);
    });
    it("works with multiple options", function () {
      var moduleName = getName();
      defineOptionModule(moduleName, this);
      expect(this.counter).toEqual(1);
      EasyGem.loadModule(moduleName, 5, 9);
      expect(this.counter).toEqual(15);
    });
    it("works with multiple options - loadModules", function () {
      var moduleName = getName();
      defineOptionModule(moduleName, this);
      expect(this.counter).toEqual(1);
      EasyGem.loadModules([moduleName], 5, 9);
      expect(this.counter).toEqual(15);
    });
  });
  describe("complex", function () {
    describe("handle define after request", function () {
      it("option", function () {
        var moduleName = getName();
        expect(this.counter).toEqual(1);
        EasyGem.loadModule(moduleName, 8);
        expect(this.counter).toEqual(1);
        defineOptionModule(moduleName, this);
        resolveModules();
        expect(this.counter).toEqual(9);
      });
      it("callback", function () {
        var moduleName = getName();
        expect(this.counter).toEqual(1);
        EasyGem.loadModule(moduleName, function (module) {
          module.add(3);
        });
        expect(this.counter).toEqual(1);
        defineCallbackModule(moduleName, this);
        resolveModules();
        expect(this.counter).toEqual(4);
      });
    });
    describe("parts", function () {
      it("define first", function () {
        var moduleName = getName();
        var self = this;
        EasyGem.module.part(moduleName, [], function () {
          this.add = function (option) {
            self.add(option);
          }
        });
        EasyGem.module.part(moduleName, function () {
          this.addDouble = function (option) {
            self.add(option * 2);
          }
        });
        expect(this.counter).toEqual(1);
        EasyGem.loadModule(moduleName, function (module) {
          module.add(3);
          module.addDouble(2);
        });
        expect(this.counter).toEqual(8);
      });
      it("request first", function () {
        var moduleName = getName();
        var self = this;
        EasyGem.loadModule(moduleName, function (module) {
          module.add(3);
          module.addDouble(2);
        });
        expect(this.counter).toEqual(1);
        EasyGem.module.part(moduleName, [], function () {
          this.add = function (option) {
            self.add(option);
          }
        });
        expect(this.counter).toEqual(1);
        EasyGem.module.part(moduleName, function () {
          this.addDouble = function (option) {
            self.add(option * 2);
          }
        });
        resolveModules();
        expect(this.counter).toEqual(8);
      });
    });
    it("handle complex tree", function () {
      var moduleName = getName();
      var subModuleName1 = getName();
      var subModuleName2 = getName();
      EasyGem.module.module(moduleName, [subModuleName1, subModuleName2], function (sub1, sub2) {
        this.sub1 = sub1;
        this.sub2 = sub2;
      });
      expect(this.counter).toEqual(1);
      EasyGem.loadModule(moduleName, function (module) {
        module.sub1(2);
        module.sub2.add(3);
      });
      resolveModules();
      expect(this.counter).toEqual(1);
      defineOptionModule(subModuleName1, this);
      resolveModules();
      expect(this.counter).toEqual(1);
      defineCallbackModule(subModuleName2, this);
      resolveModules();
      expect(this.counter).toEqual(6);
    });
  });
});
