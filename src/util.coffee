typeShouldBe = (type) -> (val) ->
  Object.prototype.toString.call(val) is type

module.exports =

  isString: (val) ->
    typeShouldBe('[object String]')(val)

  isNumber: (val) ->
    typeShouldBe('[object Number]')(val)

  isBoolean: (val) ->
    typeShouldBe('[object Boolean]')(val)

  isObject: (val) ->
    typeShouldBe('[object Object]')(val)

  isArray: (val) ->
    typeShouldBe('[object Array]')(val)
