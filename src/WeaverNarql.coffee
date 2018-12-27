Weaver      = require('./Weaver')

class WeaverNarql

  constructor: (@_query, @target) ->
    @_limit              = 99999
    @_skip               = 0

  skip: (skip) ->
    if typeof skip isnt 'number' or skip < 0
      throw new Error('Invalid argument: skip should be a positive number')

    @_skip = skip
    @

  limit: (limit) ->
    if typeof limit isnt 'number' or limit < 0
      throw new Error('Invalid argument: limit should be a positive number')

    @_limit = limit
    @

  useCache: ->
    @_useCache = true

  refreshCache: ->
    @_refreshCache = true

  find:  ->
    Weaver.getCoreManager().narql(@).then((result) =>
      resultMap = {}
      for binding, list of result
        resultMap[binding] = new Weaver.NodeList()
        for object in list
          resultMap[binding].push(Weaver.Node.loadFromQuery(object))
      resultMap
    )

# Export
module.exports = WeaverNarql
