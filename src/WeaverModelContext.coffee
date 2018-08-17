Promise              = require('bluebird')
semver               = require('semver')

class WeaverModelContext
  constructor: (definition, model) ->
    @definition = definition
    @model = model or @
    @_graph = "#{@definition.name}-#{semver.major(@definition.version)}"

  getGraph: ->
    @_graph

  includeKeyToModelTab: (key) ->
    object = @definition.includes?[key]
    if object?
      "#{object.name}@#{object.version}"
    else
      null

  isNativeClass: (className) ->
    className.indexOf('.') is -1

  # eg test-model:td.Document is processed from [test-model:td][Document] to [test-doc-model][Document]
  getNodeNameByKey: (dotPath) ->
    [first, rest...] = dotPath.split('.')
    return "#{@definition.name}:#{dotPath}" if rest.length is 0 and dotPath.indexOf(':') < 0
    return "#{dotPath}" if rest.length is 0 and dotPath.indexOf(':') >= 0

    if first.indexOf(':') < 0
      tag = @includeKeyToModelTab(first)
      if tag?
        context = @model.contextMap[tag]
        return context.getNodeNameByKey(rest.join('.'))
    else
      throw new Error("This route is deprecated")

    return null

module.exports = WeaverModelContext
