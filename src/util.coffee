module.exports =

isObject: (object) ->
  Object.prototype.toString.call(object) is '[object Object]'

isArray: (object) ->
  Object.prototype.toString.call(object) is '[object Array]'