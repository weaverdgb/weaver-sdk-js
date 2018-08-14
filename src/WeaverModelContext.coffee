Promise              = require('bluebird')

class WeaverModelContext
  constructor: (@definition) ->

  isNativeClass: (className) ->
    className.indexOf('.') is -1

  # eg test-model:td.Document is processed from [test-model:td][Document] to [test-doc-model][Document]
  getNodeNameByKey: (dotPath) ->
    [first, rest...] = dotPath.split('.')
    return "#{@definition.name}:#{dotPath}" if rest.length is 0 and dotPath.indexOf(':') < 0
    return "#{dotPath}" if rest.length is 0 and dotPath.indexOf(':') >= 0

    if first.indexOf(':') < 0
      if @includes[first]?
        m = @includes[first]
        return m.getNodeNameByKey(rest.join('.'))
    else
      [modelName, prefix] = first.split(':')
      if @modelMap[modelName]? and @modelMap[modelName].includes[prefix]?
        m = @modelMap[modelName].includes[prefix]
        return m.getNodeNameByKey(rest.join('.'))

    return null



    

module.exports = WeaverModelContext
