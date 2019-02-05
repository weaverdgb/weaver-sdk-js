_           = require('lodash')
Weaver      = require('./Weaver')

class WeaverSparql

  constructor: (@_query, @target) ->
    @_limit              = 99999
    @_skip               = 0
    @_nextResults        = false
    @_keepOpen           = false
    @_autoClose          = false

  next: ->
    @_nextResults = true
    @find()

  _getTransaction: ->
    trx = Weaver.getCoreManager().currentTransaction
    if !trx?
      if @_keepOpen
        @_autoClose = true
        Weaver.getInstance().startTransaction()
      else
        Promise.resolve(undefined)
    else
      Promise.resolve(trx)

  find: ->
    resultMap = {}
    clone = @preSerialize()
    trx = Weaver.getCoreManager().currentTransaction
    throw new Error('Not able to retrieve next results from a query without open transaction') if !trx? && @_nextResults
    @_getTransaction.then((trx) =>
      if trx?
        clone._transaction = trx.id()
      Weaver.getCoreManager().sparql(clone)
    ).then((result) =>
      for binding, list of result
        resultMap[binding] = new Weaver.NodeList()
        for object in list
          resultMap[binding].push(Weaver.Node.loadFromQuery(object))
      if @_autoClose && !@_keepOpen
        Weaver.getCoreManager().currentTransaction.commit()
    ).then(=>
      resultMap
    )

  close: ->
    Weaver.getCoreManager().currentTransaction.commit()
  
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

  keepOpen: (keepOpen = true) ->
    @_keepOpen = keepOpen
    @

  useCache: (set = true) ->
    @_useCache = set
    @

  refreshCache: (set = true) ->
    @_refreshCache = set
    @

  preSerialize: ->
    _.omit(@, [])

# Export
module.exports = WeaverSparql
