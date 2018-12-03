cuid             = require('cuid')
Operation        = require('./Operation')
Weaver           = require('./Weaver')
util             = require('./util')
_                = require('lodash')
moment           = require('moment')
Promise          = require('bluebird')
WeaverError      = require('./WeaverError')
WeaverRelationIn = require('./WeaverRelationIn')

class WeaverNode

  constructor: (@nodeId, @graph) ->
    # Generate random id if not given
    @nodeId ?= cuid()
    @_stored = false       # if true, available in database, local node can hold unsaved changes
    @_loaded = false       # if true, all information from the database was localised on construction
    # Store all attributes and relations in these objects
    @_attributes  = {}
    @_relations   = {}
    @relationsIn  = {}

    # All operations that need to get saved
    @_pendingWrites = [Operation.Node(@).createNode()]
    @_createdAt = @_pendingWrites[0].timestamp
    @_createdBy = Weaver.instance?.currentUser()?.userId

    Weaver.publish('node.created', @)

  identityString: ->
    "#{@graph}:#{@nodeId}"

  # Node loading from server
  @load: (nodeId, target, Constructor, includeRelations = false, includeAttributes = false, graph) ->
    if !nodeId?
      Promise.reject("Cannot load nodes with an undefined id")
    else
      Constructor = WeaverNode if not Constructor?
      query = new Weaver.Query(target)
      query.withRelations() if includeRelations
      query.withAttributes() if includeAttributes
      query.get(nodeId, Constructor, graph)

  @loadFromGraph: (nodeId, graph, Constructor) ->
    if !nodeId?
      Promise.reject("Cannot load nodes with an undefined id")
    else
      @load(nodeId, undefined, Constructor, false, false, graph)


  @loadFromQuery: (object, constructorFunction, fullyLoaded=true, model) ->

    if constructorFunction?
      Constructor = constructorFunction(Weaver.Node.loadFromQuery(object, undefined, undefined, model))
    if !Constructor?
      Constructor = if model? then Weaver.DefinedNode else Weaver.Node
    if object.relationSource? and object.relationTarget?
      Constructor = Weaver.RelationNode

    instance = new Constructor(object.nodeId, object.graph, model)
    instance._loadFromQuery(object, constructorFunction, fullyLoaded, model)
    instance._setStored()
    if instance instanceof Weaver.RelationNode
      instance.fromNode = WeaverNode.loadFromQuery(object.relationSource, undefined, false)
      instance.toNode   = WeaverNode.loadFromQuery(object.relationTarget, undefined, false)
      instance.key      = object.relationKey
    instance

  _loadFromQuery: (object, constructorFunction, fullyLoaded=true, model) ->

    @_attributes = object.attributes
    @_loaded    = object.creator? && fullyLoaded
    @_createdAt = object.created
    @_createdBy = object.creator

    for key, relations of object.relationsIn
      for relation in relations
        if constructorFunction?
          Constructor = constructorFunction(Weaver.Node.loadFromQuery(relation.source, undefined, undefined, model), @, key)
        if !Constructor?
          Constructor = if model? then Weaver.DefinedNode else Weaver.Node

        instance = new Constructor(relation.source.nodeId, relation.source.graph, model)
        instance._loadFromQuery(relation.source, constructorFunction, fullyLoaded, model)
        @_loadRelationInFromQuery(key, instance, relation.nodeId, relation.graph)

    for key, relations of object.relations
      for relation in relations

        if constructorFunction?
          Constructor = constructorFunction(Weaver.Node.loadFromQuery(relation.target, undefined, undefined, model), @, key)
        if !Constructor?
          Constructor = if model? then Weaver.DefinedNode else Weaver.Node

        instance = new Constructor(relation.target.nodeId, relation.target.graph, model)
        instance._loadFromQuery(relation.target, constructorFunction, fullyLoaded, model)
        @_loadRelationFromQuery(key, instance, relation.nodeId, relation.graph)

    @_clearPendingWrites()
    Weaver.publish('node.loaded', @)
    @

  _loadRelationFromQuery: (key, instance, relId, graph)->
    @relation(key).add(instance, relId, false, graph)

  _loadRelationInFromQuery: (key, instance, nodeId, graph)->
    @relationsIn[key] ?= new WeaverRelationIn(key)
    @relationsIn[key].addSource(instance)

  # Loads current node
  load: ->
    @constructor.loadFromGraph(@id(), @getGraph()).then((loadedNode) =>
      @[key] = value for key, value of loadedNode when !_.isFunction(value)
      @
    )

  # Node creating for in queries
  @get: (nodeId, Constructor, graph) ->
    Constructor = WeaverNode if not Constructor?
    node = new Constructor(nodeId, graph)
    node._clearPendingWrites()
    node

  @getFromGraph: (nodeId, graph) ->
    @get(nodeId, undefined, graph)

  @firstOrCreate: (nodeId, Constructor, graph) ->
    new Weaver.Query()
      .get(nodeId, Constructor, graph)
      .catch(->
        Constructor = WeaverNode if not Constructor?
        new Constructor(nodeId, graph).save()
      )

  @firstOrCreateInGraph: (nodeId, graph) ->
    @firstOrCreate(nodeId, undefined, graph)

  # Return id
  id: ->
    @nodeId

  attributes: ->
    attributes = {}
    for key of @_attributes
      attributes[key] = @get(key)

    attributes

  relations: ->
    @_relations

  _getAttributeValue: (attribute) ->
    date = util.parseDate(attribute.dataType, attribute.value)
    if date?
      return date
    else
      return attribute.value

  _getAttributeDataType: (attribute) ->
    return attribute.dataType

  # Gets attributes
  get: (field) ->
    fieldArray = @_attributes[field]

    if not fieldArray? or fieldArray.length is 0
      return undefined
    else
      return @_getAttributeValue(fieldArray[0])

  getDataType: (field) ->
    fieldArray = @_attributes[field]

    if not fieldArray? or fieldArray.length is 0
      return undefined
    else
      return @_getAttributeDataType(fieldArray[0])

  getGraph: ->
    @graph

  set: (field, value, dataType, options, graph) ->
    if field is 'id'
      throw Error("Attribute 'id' cannot be set or updated")

    # Get attribute datatype, TODO: Support date
    if not dataType?
      if util.isString(value)
        dataType = 'string'
      else if util.isNumber(value)
        dataType = 'double'
      else if util.isBoolean(value)
        dataType = 'boolean'
      else if util.isDate(value)
        dataType = 'date'
        value = value.toJSON()
      else
        throw Error("Unsupported datatype for value " + value)

    # TODO validate dataType

    eventMsg  = 'node.attribute'
    eventData = {
      node: @
      field,
      value: value
      graph: graph
    }

    if @_attributes[field]?
      if @_attributes[field].length > 1
        throw new Error("Specifiy which attribute to set, more than 1 found for " + field) # TODO: Support later

      oldAttribute = @_attributes[field][0]
      eventData.oldValue = oldAttribute.value

      eventMsg += '.update'
      newAttributeOperation = Operation.Node(@).createAttribute(field, value, dataType, oldAttribute, Weaver.getInstance()._ignoresOutOfDate if !options?.ignoresOutOfDate?, graph)
    else
      eventMsg += '.set'
      newAttributeOperation = Operation.Node(@).createAttribute(field, value, dataType, null, null, graph)

    newAttribute = {
      nodeId: newAttributeOperation.id
      dataType
      value
      key: field
      created: newAttributeOperation.timestamp
      attributes: {}
      relations: {}
      graph: graph
    }

    @_attributes[field] = [newAttribute]
    Weaver.publish(eventMsg, eventData)
    @_pendingWrites.push(newAttributeOperation)

    return @


  # Update attribute by incrementing the value, the result depends on concurrent requests, so check the result
  increment: (field, value = 1, project) ->
    if not @_attributes[field]?
      throw new Error("There is no field " + field + " to increment")
    if typeof value isnt 'number'
      throw new Error("Field " + field + " is not a number")

    currentValue = @get(field)
    pendingNewValue = currentValue + value
    wasIgnoring = Weaver.getInstance()._ignoresOutOfDate
    Weaver.getInstance()._ignoresOutOfDate = false
    @set(field, pendingNewValue)
    Weaver.getInstance()._ignoresOutOfDate = wasIgnoring

    # To be backwards compatible, but its better not to save here
    @save().then(=>
      # Return the incremented value
      pendingNewValue
    ).catch((error) =>
      if (error.code == WeaverError.WRITE_OPERATION_INVALID)
        index = @_pendingWrites.map((o) => o.key).indexOf(field) # find failed operation
        @_pendingWrites.splice(index, 1) if index > -1 # remove failing operation, otherwise the save() keeps on failing on this node
        @_incrementOfOutSync(field, value, project)
      else
        Promise.reject(error)
    )

  _incrementOfOutSync: (field, value, project) ->

    new Weaver.Query()
    .select(field)
    .restrict(@id())
    .restrictGraphs(@graph)
    .first()
    .then((loadedNode) =>
      currentValue = loadedNode.get(field)
      pendingNewValue = currentValue + value
      wasIgnoring = Weaver.getInstance()._ignoresOutOfDate
      Weaver.getInstance()._ignoresOutOfDate = false
      loadedNode.set(field, pendingNewValue)
      Weaver.getInstance()._ignoresOutOfDate = wasIgnoring

      # To be backwards compatible, but its better not to save here
      loadedNode.save().then(->
        # Return the incremented value
        pendingNewValue
      ).catch(=>
        @_incrementOfOutSync(field, value, project)
      )
    )


  # Remove attribute
  unset: (field) ->
    if not @_attributes[field]?
      throw new Error("There is no field " + field + " to unset")

    if @_attributes[field].length > 1
      throw new Error("Currently not possible to unset is multiple attributes are present")

    currentAttribute = @_attributes[field][0]

    # Save change as pending
    @_pendingWrites.push(Operation.Node(@).removeAttribute(currentAttribute.nodeId))

    Weaver.publish('node.attribute.unset', {node: @, field})

    # Unset locally
    delete @_attributes[field]
    @


  # Create a new Relation
  relation: (key, Constructor = Weaver.Relation) ->
    @_relations[key] = new Constructor(@, key) if not @_relations[key]?
    @_relations[key]

  # always clones a node to the same graph as its original node
  clone: (newId, relationTraversal...) ->
    cm = Weaver.getCoreManager()
    cm.cloneNode(@nodeId, newId, relationTraversal, @graph)

  cloneToGraph: (newId, graph, relationTraversal...) ->
    cm = Weaver.getCoreManager()
    cm.cloneNode(@nodeId, newId, relationTraversal, @graph, graph)

  peekPendingWrites: ->
    @_collectPendingWrites(undefined, false)

  # Go through each relation and recursively add all pendingWrites per relation AND that of the objects
  _collectPendingWrites: (collected = [], cleanup=true) ->
    # Register to keep track which nodes have been collected to prevent recursive blowup
    collected.push(@) if @ not in collected
    operations = @_pendingWrites
    if not operations?
      return []

    if cleanup
      @_pendingWrites = []
      i.__pendingOpNode = @ for i in operations

    for key, relation of @_relations
      for node in relation.all() when node not in collected
        collected.push(node)
        operations = operations.concat(node._collectPendingWrites(collected, cleanup))

      operations = operations.concat(relation._pendingWrites)

      for record in relation.allRecords() when record.relNode not in collected
        collected.push(record.relNode)
        operations = operations.concat(record.relNode._collectPendingWrites(collected, cleanup))

      if cleanup
        i.__pendingOpNode = relation for i in relation._pendingWrites
        relation._pendingWrites = []

    operations


  # Clear all pendingWrites, used for instance after saving or when loading a node
  _clearPendingWrites: ->
    @_pendingWrites = []

    for key, relation of @_relations
      for node in relation.all()
        node._clearPendingWrites() if node.isDirty()

      relation._pendingWrites = []

  _setStored: ->
    @_stored = true

    for key, relation of @_relations
      for record in relation.allRecords()
        record.toNode._setStored() if not record.toNode._stored
        record.relNode._setStored() if not record.relNode._stored
    @


  # Checks whether needs saving
  isDirty: ->
    @_pendingWrites.length isnt 0


  # Save node and all values / relations and relation objects to server
  save: (project) ->
    cm = Weaver.getCoreManager()
    writes = @_collectPendingWrites()

    cm.enqueue(=>
      cm.executeOperations((_.omit(i, "__pendingOpNode") for i in writes), project).then(=>
        Weaver.publish('node.saved', i.__pendingOpNode) for i in writes
        @_setStored()
        @
      ).catch((e) =>

        # Restore the pending writes to their originating nodes
        # (in reverse order so create-node is done before adding attributes)
        for i in writes by -1
          i.__pendingOpNode._pendingWrites.unshift(i)

        Promise.reject(e)
      )
    )

  @batchSave: (array, project) ->
    cm = Weaver.getCoreManager()
    writes = [].concat.apply([], (i._collectPendingWrites() for i in array))
    cm.enqueue(=>
      cm.executeOperations((_.omit(i, "__pendingOpNode") for i in writes), project).then(->
        i.__pendingOpNode._setStored() for i in writes when i.__pendingOpNode._setStored?
        Promise.resolve()
      ).catch((e) =>

        # Restore the pending writes to their originating nodes
        # (in reverse order so create-node is done before adding attributes)

        for i in writes by -1
          i.__pendingOpNode._pendingWrites.unshift(i)

        Promise.reject(e)
      )
    )

  # Removes node, with the option to remove it unrecoverable
  destroy: (project, unrecoverableRemove = false, propagates = [], propagationDepth = 1) =>
    if propagationDepth isnt 0
      for predicate in propagates
        @relation(predicate).all().map((node)->
          node.destroy(project, unrecoverableRemove, propagates, --propagationDepth)
        )

    cm = Weaver.getCoreManager()
    cm.enqueue( =>

      if (Weaver.getInstance()._unrecoverableRemove or unrecoverableRemove)
        if @nodeId?
          cm.executeOperations([Operation.Node(@).removeNodeUnrecoverable()], project).then(=>
            Weaver.publish('node.destroyed', @id())
            delete @[key] for key of @
            undefined
          )
        else
          undefined
      else
        if @nodeId?
          cm.executeOperations([Operation.Node(@).removeNode()], project).then(=>
            Weaver.publish('node.destroyed', @id())
            delete @[key] for key of @
            undefined
          )
        else
          undefined
    )

  # Removes nodes in batch
  @batchDestroy: (array, project) ->
    cm = Weaver.getCoreManager()
    cm.enqueue(=>
      if array? and array.length isnt 0
        try
          destroyOperations = (Operation.Node(node).removeNode() for node in array)
          cm.executeOperations(destroyOperations, project).then(=>
            Promise.resolve()
          ).catch((e) =>
            Promise.reject(e)
          )
        catch error
          Promise.reject(error)
      else
        Promise.reject("Cannot batch destroy nodes without any node")
    )

  # TODO: Implement
  setACL: (acl) ->
    return

  equals: (node) ->
    node instanceof WeaverNode and node.id() is @id() and node.getGraph() is @getGraph()

  createdAt: ->
    @_createdAt

  createdBy: ->
    @_createdBy

  wpath: (expr='', func, load=false) ->
    hops = expr.split('/')
    hops.splice(0,1) if hops[0] is ''
    res = []
    @_executeWpath(hops, res)
    func(row) for row in res if func?
    res

  _executeWpath: (hops, res=[], trail={}) ->

    newRow = (blueprint)->
      row = {}
      row[binding] = node for binding, node of blueprint
      row

    [hop, hops...] = hops
    if !hop?
      res.push(trail) if _.keys(trail).length > 0
      return 
    [key, binding] = hop.split('?')

    # Optionally get the [] filter
    [key, filter] = key.split('[')
    [filter, ...] = filter.split(']') if filter?

    if not @ instanceof Weaver.ModelClass or @isAllowedRelation(key)
      for node in @relation(key).all()
        if @_filterWpath(node, filter)
          row = newRow(trail)
          row[binding] = node if binding?
          node._executeWpath(hops, res, row)

  _filterWpath: (node, expr) ->
    return true if !expr?

    hasOrs = expr.indexOf('|') > -1
    hasAnds = expr.indexOf('&') > -1

    throw new Error("Wpath does not support combination of AND and OR") if hasOrs && hasAnds

    value = !hasOrs

    conditions = [expr]
    conditions = expr.split('|') if hasOrs
    conditions = expr.split('&') if hasAnds

    for condition in conditions
      met = undefined
      [action, key] = condition.split('=')
      switch action.trim()
        when 'id' 
          met = node.id() is key
        when 'class' 
          met = false
          if node.model?
            met |= def.id() is key for def in  node.relation(node.model.getMemberKey()).all()
        else throw new Error("Key #{action} not supported in wpath")
      if hasOrs
        value |= met
      else 
        value &= met

    value


# Export
module.exports = WeaverNode
