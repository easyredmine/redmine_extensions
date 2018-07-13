describe("EasyGem.extend",function () {
  var target = {
    array: ["a", "b"],
    c: {f: 5, t: 8, arr: [{a: 7, b: 3}]},
    f: [5, 6, 7]
  };
  var source = {
    array: ["c"],
    c: {f: 6, g: 5, arr: [{v: 1, b: 2}, {ff: 1}]},
    k: {a: "g"}
  };
  it("shallow",function () {
    var e1 = {
      array: ["c"],
      c: {f: 6, g: 5, arr: [{v: 1, b: 2}, {ff: 1}]},
      f: [5, 6, 7],
      k: {a: "g"}
    };
    var r1 = EasyGem.extend(JSON.parse(JSON.stringify(target)), JSON.parse(JSON.stringify(source)));
    expect(r1).toEqual(e1);
  });
  it("deep",function () {
    var e2 = {
      array: ["c", "b"],
      c: {f: 6, g: 5, t: 8, arr: [{a: 7, v: 1, b: 2}, {ff: 1}]},
      f: [5, 6, 7],
      k: {a: "g"}
    };
    var r2 = EasyGem.extend(true,JSON.parse(JSON.stringify(target)), JSON.parse(JSON.stringify(source)));
    expect(r2).toEqual(e2);
  });
});