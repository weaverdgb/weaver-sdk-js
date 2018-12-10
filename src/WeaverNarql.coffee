Weaver      = require('./Weaver')

class WeaverNarql

  constructor: (@_query, @target) ->
    @_limit              = 99999
    @_skip               = 0

  skip: (skip) ->
    if typeof skip isnt 'number' or skip < 0
      throw new Error('You can only skip by a positive number')

    @_skip = skip
    @

  limit: (limit) ->
    if typeof limit isnt 'number' or limit < 0
      throw new Error('You can only set the limit to a positive number')

    @_limit = limit
    @

  find:  ->
    Weaver.getCoreManager().narql(@).then((result) =>
      resultMap = {}
      for binding, list of result
        resultMap[binding] = new Weaver.NodeList()
        for object in list
          castedNode = Weaver.Node.loadFromQuery(object)
          resultMap[binding].push(castedNode)
      resultMap
    )

# Export
module.exports = WeaverNarql
