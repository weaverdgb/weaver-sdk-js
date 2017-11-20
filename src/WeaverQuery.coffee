util        = require('./util')
Weaver      = require('./Weaver')
_           = require('lodash')

# Converts a string into a regex that matches it.
# Surrounding with \Q .. \E does this, we just need to escape any \E's in
# the text separately.
quote = (s) ->
  '\\Q' + s.replace('\\E', '\\E\\\\E\\Q') + '\\E'

nodeId = (node) ->
  if _.isString(node)
    node
  else if node instanceof Weaver.Node
    node.id()
  else
    throw new Error("Unsupported type")


class WeaverQuery

  @profilers = []

  constructor: (@target) ->
    @_restrict           = []
    @_equals             = {}
    @_orQueries          = []
    @_conditions         = {}
    @_include            = []
    @_select             = undefined
    @_selectOut          = []
    @_selectRecursiveOut = []
    @_recursiveConditions= []
    @_alwaysLoadRelations= []
    @_noRelations        = true
    @_noAttributes       = true
    @_count              = false
    @_hollow             = false
    @_limit              = 99999
    @_skip               = 0
    @_order              = []
    @_ascending          = true
    @_arrayCount         = 0

  find: (Constructor) ->

    if Constructor?
      @useConstructorFunction = -> Constructor

    Weaver.getCoreManager().query(@).then((result) =>
      Weaver.Query.notify(result)
      list = []
      for node in result.nodes
        castedNode = Weaver.Node.loadFromQuery(node, @useConstructorFunction, !@_select?)

        list.push(castedNode)
      list
    )

  count: ->
    @_count = true
    Weaver.getCoreManager().query(@).then((result) ->
      Weaver.Query.notify(result)
      result.count
    ).finally(=>
      @_count = false
    )

  first: (Constructor) ->
    @_limit = 1
    @find(Constructor).then((res) ->
      if res.length is 0
        Promise.reject({code:101, "Node not found"})
      else
        res[0]
    )

  get: (node, Constructor) ->
    @restrict(node)
    @first(Constructor)

  restrict: (nodes) ->

    addRestrict = (node) =>
      if util.isString(node)
        @_restrict.push(node)
      else if node instanceof Weaver.Node
        @_restrict.push(node.id())

    if util.isArray(nodes)
      @_restrict = [] # Clear
      addRestrict(node) for node in nodes
    else
      addRestrict(nodes)

    @

  _addCondition: (key, condition, value) ->
    delete @_equals[key]
    @_conditions[key] = @_conditions[key] or {}
    @_conditions[key][condition] = value
    @

  equalTo: (key, value) ->
    delete @_conditions[key]
    @_equals[key] = value
    @

  notEqualTo: (key, value) ->
    @_addCondition(key, '$ne', value)

  lessThan: (key, value) ->
    @_addCondition(key, '$lt', value)

  greaterThan: (key, value) ->
    @_addCondition(key, '$gt', value)

  lessThanOrEqualTo: (key, value) ->
    @_addCondition(key, '$lte', value)

  greaterThanOrEqualTo: (key, value) ->
    @_addCondition(key, '$gte', value)

  hasRelationIn: (key, node...) ->
    if _.isArray(key)
      @_addCondition("$relationArray${@arrayCount++}", '$relIn', key)
    else if node.length is 1 and node[0] instanceof WeaverQuery
      @_addCondition(key, '$relIn', node)
    else
      @_addCondition(key, '$relIn', if node.length > 0 then (nodeId(i) or i for i in node) else ['*'])

  hasRelationOut: (key, node...) ->
    if _.isArray(key)
      @_addCondition("$relationArray${@arrayCount++}", '$relOut', key)
    else if node.length is 1 and node[0] instanceof WeaverQuery
      @_addCondition(key, '$relOut', node)
    else
      @_addCondition(key, '$relOut', if node.length > 0 then (nodeId(i) or i for i in node) else ['*'])
    @

  hasNoRelationIn: (key, node...) ->
    if _.isArray(key)
      @_addCondition("$relationArray${@arrayCount++}", '$noRelIn', key)
    else if node.length is 1 and node[0] instanceof WeaverQuery
      @_addCondition(key, '$noRelIn', node)
    else
      @_addCondition(key, '$noRelIn', if node.length > 0 then (nodeId(i) or i for i in node) else ['*'])

  hasNoRelationOut: (key, node...) ->
    if _.isArray(key)
      @_addCondition("$relationArray${@arrayCount++}", '$noRelOut', key)
    else if node.length is 1 and node[0] instanceof WeaverQuery
      @_addCondition(key, '$noRelOut', node)
    else
      @_addCondition(key, '$noRelOut', if node.length > 0 then (nodeId(i) or i for i in node) else ['*'])

  _addRecursiveCondition: (op, relation, node, includeSelf) ->
    target = if node instanceof Weaver.Node
      node.id()
    else
      node
    @_recursiveConditions.push({
      operation: op
      relation
      nodeId: target
      includeSelf
    })
    @

  hasNoRecursiveRelationIn: (key, node, includeSelf = false) ->
    @_addRecursiveCondition('$noRelIn', key, node, includeSelf)
    
  hasNoRecursiveRelationOut: (key, node, includeSelf = false) ->
    @_addRecursiveCondition('$noRelOut', key, node, includeSelf)

  hasRecursiveRelationIn: (key, node, includeSelf = false) ->
    @_addRecursiveCondition('$relIn', key, node, includeSelf)
    
  hasRecursiveRelationOut: (key, node, includeSelf = false) ->
    @_addRecursiveCondition('$relOut', key, node, includeSelf)
    
  containedIn: (key, values) ->
    @_addCondition(key, '$in', values)

  notContainedIn: (key, values) ->
    @_addCondition(key, '$nin', values)

  containsAll: (key, values) ->
    @_addCondition(key, '$all', values)

  exists: (key) ->
    @_addCondition(key, '$exists', true)

  doesNotExist: (key) ->
    @_addCondition(key, '$exists', false)

  matches: (key, value) ->
    @_addCondition(key, '$regex', value)

  contains: (key, value) ->
    @_addCondition(key, '$contains', value)

  startsWith: (key, value) ->
    @_addCondition(key, '$regex', '^' + quote(value))

  endsWith: (key, value) ->
    @_addCondition(key, '$regex', quote(value) + '$')

  matchesQuery: (key, weaverQuery) ->
    @_addCondition(key, '$inQuery', weaverQuery)

  doesNotMatchQuery: (key, query) ->
    @_addCondition(key, '$notInQuery', query)

  matchesKeyQuery: (key, queryKey, query) ->
    @_addCondition(key, '$select', {queryKey, query})

  doesNotMatchKeyInQuery: (key, queryKey, query) ->
    @_addCondition(key, '$dontSelect', {queryKey, query})

  withAttributes: ->
    @_noAttributes = false
    @

  withRelations: ->
    @_noRelations = false
    @

  noRelations: ->
    @_noRelations = true
    @

  noAttributes: ->
    @_noAttributes = true
    @

  order: (keys, ascending) ->
    @_order     = keys
    @_ascending = ascending
    @

  ascending: (keys) ->
    @order(keys, true)

  descending: (keys) ->
    @order(keys, false)

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

  include: (keys) ->
    @_include = keys
    @

  select: (keys...) ->
    @_select = keys
    @

  selectOut: (relationKeys...) ->
    @_selectOut.push(relationKeys)
    @

  selectRecursiveOut: (relationKeys...) ->
    @_selectRecursiveOut = relationKeys
    @

  alwaysLoadRelations: (relationKeys...) ->
    @_alwaysLoadRelations.push(i) for i in relationKeys
    @

  hollow: (value) ->
    @_hollow = value
    @

  or: (queries) ->
    @_orQueries = queries
    @

  @or: (queries) ->
    query = new Weaver.Query()
    query.or(queries)
    query

  @profile: (callback) ->
    Weaver.Query.profilers.push(callback)

  @clearProfilers: ->
    Weaver.Query.profilers = []

  @notify: (result) ->
    for callback in Weaver.Query.profilers
      callback(result)

  useConstructor: (useConstructorFunction) ->
    @useConstructorFunction = useConstructorFunction
    @

  # Create, Update, Enter, Leave, Delete
  subscribe: ->
    Weaver.getCoreManager().subscribe(@)

  nativeQuery: (query)->
    Weaver.getCoreManager().nativeQuery(query, Weaver.getInstance().currentProject().id())

# Export
module.exports = WeaverQuery
