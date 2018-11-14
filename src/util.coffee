moment = require('moment')

typeShouldBe = (type) -> (val) ->
  Object.prototype.toString.call(val) is type

flatten = (arr) ->
  arr.reduce((flat, toFlatten) ->
    return flat.concat(flatten(toFlatten)) if typeShouldBe('[object Array]')(toFlatten)
    return flat.concat(toFlatten)
  , [])

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

  isDate: (val) ->
    throw new Error('Please use momentjs Date instances') if val instanceof Date
    moment.isMoment(val)

  parseDate: (dataType, value) ->
    switch dataType
      when 'date'           then moment(value)
      when 'xsd:dateTime'   then moment(value)
      else undefined

  flatten: flatten
