util        = require('./util')
Weaver      = require('./Weaver')
_           = require('lodash')

# Converts a string into a regex that matches it.
# Surrounding with \Q .. \E does this, we just need to escape any \E's in
# the text separately.
quote = (s) ->
  '\\Q' + s.replace('\\E', '\\E\\\\E\\Q') + '\\E'


class WeaverQuery

  constructor: (@target) ->
    @_restrict     = []
    @_equals       = {}
    @_orQueries    = []
    @_conditions   = {}
    @_relationsOut = []
    @_include      = []
    @_select       = []
    @_noRelations  = true
    @_noAttributes = true
    @_count        = false
    @_hollow       = false
    @_limit        = 99999
    @_skip         = 0
    @_order        = []
    @_ascending    = true

  find: (Constructor) ->

    Constructor = Constructor or Weaver.Node
    Weaver.getCoreManager().query(@).then((result) ->
      list = []
      for node in result.nodes
        instance = new Constructor(node.nodeId)
        instance._loadFromQuery(node)
        instance._setStored()
        instance._loaded = true

        list.push(instance)
      list
    )

  count: ->
    @_count = true
    Weaver.getCoreManager().query(@).then((result) ->
      result.count
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
    if node.length is 1 and node[0] instanceof WeaverQuery
      @_addCondition(key, '$relIn', node)
    else
      @_addCondition(key, '$relIn', if node.length > 0 then (i.id() or i for i in node) else ['*'])

  hasRelationOut: (key, node...) ->
    if _.isArray(key)
      @_relationsOut = key # values are ignored
    else if node.length is 1 and node[0] instanceof WeaverQuery
      @_addCondition(key, '$relOut', node)
    else
      @_addCondition(key, '$relOut', if node.length > 0 then (i.id() or i for i in node) else ['*'])
    @

  hasNoRelationIn: (key, node...) ->
    if node.length is 1 and node[0] instanceof WeaverQuery
      @_addCondition(key, '$noRelIn', node)
    else
      @_addCondition(key, '$noRelIn', if node.length > 0 then (i.id() or i for i in node) else ['*'])

  hasNoRelationOut: (key, node...) ->
    if node.length is 1 and node[0] instanceof WeaverQuery
      @_addCondition(key, '$noRelOut', node)
    else
      @_addCondition(key, '$noRelOut', if node.length > 0 then (i.id() or i for i in node) else ['*'])

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

  # Create, Update, Enter, Leave, Delete
  subscribe: ->
    Weaver.getCoreManager().subscribe(@)

  nativeQuery: (query)->
    Weaver.getCoreManager().nativeQuery(query, Weaver.getInstance().currentProject().id())

# Export
module.exports = WeaverQuery
