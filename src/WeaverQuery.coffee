util        = require('./util')
Weaver      = require('./Weaver')
_           = require('lodash')

# Converts a string into a regex that matches it.
# Surrounding with \Q .. \E does this, we just need to escape any \E's in
# the text separately.
quote = (s) ->
  '\\Q' + s.replace('\\E', '\\E\\\\E\\Q') + '\\E'

getNodeIdFromStringOrNode = (node) ->
  if _.isString(node)
    node
  else if node instanceof Weaver.Node
    {
      id: node.id()
      graph: node.getGraph()
    }
  else
    throw new Error("Unsupported type: #{node}")

nodeRelationArrayValue = (nodes) ->
  if nodes.length > 0
    (getNodeIdFromStringOrNode(i) for i in nodes)
  else
    ["*"]


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
    @_inGraph            = undefined

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

  get: (node, Constructor, graph) ->
    @restrict(node)
    @restrictGraphs(graph)
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

  _addRestrictGraph: (graph) ->
    if !@_inGraph?
      @_inGraph = []

    if util.isString(graph)
      @_inGraph.push(graph)
    else if graph instanceof Weaver.Graph
      @_inGraph.push(graph.id())

  inGraph: (graphs...) ->
    @_addRestrictGraph(i) for i in graphs
    @

  restrictGraphs: (graphs) ->
    if graphs?
      @_inGraph = [] # Clear
      if util.isArray(graphs)
        @_addRestrictGraph(graph) for graph in graphs
      else
        @_addRestrictGraph(graphs)
    @

  _addAttributeCondition: (key, condition, value) ->
    @_addCondition(key, condition, value)

  _addRelationCondition: (key, condition, value) ->
    @_addCondition(key, condition, value)

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
    @_addAttributeCondition(key, '$ne', value)

  lessThan: (key, value) ->
    @_addAttributeCondition(key, '$lt', value)

  greaterThan: (key, value) ->
    @_addAttributeCondition(key, '$gt', value)

  lessThanOrEqualTo: (key, value) ->
    @_addAttributeCondition(key, '$lte', value)

  greaterThanOrEqualTo: (key, value) ->
    @_addAttributeCondition(key, '$gte', value)

  hasRelationIn: (key, node...) ->
    if _.isArray(key)
      @_addRelationCondition("$relationArray${@arrayCount++}", '$relIn', key)
    else if node.length is 1 and node[0] instanceof WeaverQuery
      @_addRelationCondition(key, '$relIn', node)
    else
      @_addRelationCondition(key, '$relIn', nodeRelationArrayValue(node))

  hasRelationOut: (key, node...) ->
    if _.isArray(key)
      @_addRelationCondition("$relationArray${@arrayCount++}", '$relOut', key)
    else if node.length is 1 and node[0] instanceof WeaverQuery
      @_addRelationCondition(key, '$relOut', node)
    else
      @_addRelationCondition(key, '$relOut', nodeRelationArrayValue(node))
    @

  hasNoRelationIn: (key, node...) ->
    if _.isArray(key)
      @_addRelationCondition("$relationArray${@arrayCount++}", '$noRelIn', key)
    else if node.length is 1 and node[0] instanceof WeaverQuery
      @_addRelationCondition(key, '$noRelIn', node)
    else
      @_addRelationCondition(key, '$noRelIn', nodeRelationArrayValue(node))

  hasNoRelationOut: (key, node...) ->
    if _.isArray(key)
      @_addRelationCondition("$relationArray${@arrayCount++}", '$noRelOut', key)
    else if node.length is 1 and node[0] instanceof WeaverQuery
      @_addRelationCondition(key, '$noRelOut', node)
    else
      @_addRelationCondition(key, '$noRelOut', nodeRelationArrayValue(node))

  _addRecursiveCondition: (op, relation, node, includeSelf) ->
    nodeId = ''
    graph = undefined
    if node instanceof Weaver.Node
      nodeId = node.id()
      graph  = node.getGraph()
    else
      nodeId = node
    @_recursiveConditions.push({
      operation: op
      relation
      nodeId
      nodeGraph: graph
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
    @_addAttributeCondition(key, '$in', values)

  notContainedIn: (key, values) ->
    @_addAttributeCondition(key, '$nin', values)

  containsAll: (key, values) ->
    @_addAttributeCondition(key, '$all', values)

  exists: (key) ->
    @_addAttributeCondition(key, '$exists', true)

  doesNotExist: (key) ->
    @_addAttributeCondition(key, '$exists', false)

  matches: (key, value) ->
    @_addAttributeCondition(key, '$regex', value)

  contains: (key, value) ->
    @_addAttributeCondition(key, '$contains', value)

  startsWith: (key, value) ->
    @_addAttributeCondition(key, '$regex', '^' + quote(value))

  endsWith: (key, value) ->
    @_addAttributeCondition(key, '$regex', quote(value) + '$')

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
