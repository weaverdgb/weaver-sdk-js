Weaver      = require('./Weaver')

class WeaverSparql

  constructor: (@_query, @target) ->
    @_limit              = 99999
    @_skip               = 0

  next: () ->
    @_nextResults = true
    @find()

  find: ->
    clone = @preSerialize()
    trx = Weaver.getCoreManager().currentTransaction
    transaction = Promise.resolve(trx)
    transaction = Weaver.getInstance().startTransaction() if !trx? && @_keepOpen? && @_keepOpen
    transaction.then((trx) =>
      if trx?
        clone._transaction = trx.id()   

      Weaver.getCoreManager().sparql(clone)
    ).then((result) =>
      resultMap = {}
      for binding, list of result
        resultMap[binding] = new Weaver.NodeList()
        for object in list
          resultMap[binding].push(Weaver.Node.loadFromQuery(object))
      resultMap
    )
  
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

  batchSize: (batchSize) ->
    @_batchSize = batchSize
    @

  keepOpen: (keepOpen=true) ->
    @_keepOpen = keepOpen
    @

  useCache: (set=true) ->
    @_useCache = set
    @

  refreshCache: (set=true) ->
    @_refreshCache = set
    @

  preSerialize: ->
    _.omit(@, [])

# Export
module.exports = WeaverSparql
