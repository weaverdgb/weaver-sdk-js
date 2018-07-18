cuid             = require('cuid')
Operation        = require('./Operation')
Weaver           = require('./Weaver')
util             = require('./util')
_                = require('lodash')
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
    @pendingWrites = [Operation.Node(@).createNode()]
    @_createdAt = @pendingWrites[0].timestamp
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

  @loadFromGraph: (nodeId, graph) ->
    if !nodeId?
      Promise.reject("Cannot load nodes with an undefined id")
    else
      @load(nodeId, undefined, undefined, false, false, graph)


  @loadFromQuery: (node, constructorFunction, fullyLoaded=true, model) ->

    if constructorFunction?
      Constructor = constructorFunction(Weaver.Node.loadFromQuery(node, undefined, undefined, model))
    if !Constructor?
      Constructor = if model? then Weaver.DefinedNode else Weaver.Node
    if node.relationSource? and node.relationTarget?
      Constructor = Weaver.RelationNode

    instance = new Constructor(node.nodeId, node.graph)
    instance.model = model if model?
    instance._loadFromQuery(node, constructorFunction, fullyLoaded, model)
    instance._setStored()
    if instance instanceof Weaver.RelationNode
      instance.fromNode = WeaverNode.loadFromQuery(node.relationSource, undefined, false)
      instance.toNode   = WeaverNode.loadFromQuery(node.relationTarget, undefined, false)
      instance.key      = node.relationKey
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

        instance = new Constructor(relation.source.nodeId, relation.source.graph)
        instance.model = model if model?
        instance._loadFromQuery(relation.source, constructorFunction, fullyLoaded, model)
        @._loadRelationInFromQuery(key, instance, relation.nodeId, relation.graph)

    for key, relations of object.relations
      for relation in relations

        if constructorFunction?
          Constructor = constructorFunction(Weaver.Node.loadFromQuery(relation.target, undefined, undefined, model), @, key)
        if !Constructor?
          Constructor = if model? then Weaver.DefinedNode else Weaver.Node

        instance = new Constructor(relation.target.nodeId, relation.target.graph)
        instance.model = model if model?
        instance._loadFromQuery(relation.target, constructorFunction, fullyLoaded, model)
        @._loadRelationFromQuery(key, instance, relation.nodeId, relation.graph)

    @._clearPendingWrites()
    Weaver.publish('node.loaded', @)
    @

  _loadRelationFromQuery: (key, instance, nodeId, graph)->
    @relation(key).add(instance, nodeId, false, graph)

  _loadRelationInFromQuery: (key, instance, nodeId, graph)->
    @relationsIn[key] ?= new WeaverRelationIn(key)
    @relationsIn[key].addSource(instance)

  # Loads current node
  load: ->
    Weaver.Node.load(@nodeId).then((loadedNode) =>
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
    if attribute.dataType is 'date'
      return new Date(attribute.value)
    else
      return attribute.value

  # Gets attributes
  get: (field) ->
    fieldArray = @_attributes[field]

    if not fieldArray? or fieldArray.length is 0
      return undefined
    else if fieldArray.length is 1
      return @_getAttributeValue(fieldArray[0])
    else
      return fieldArray[0]

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
        value = value.getTime()
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
    @pendingWrites.push(newAttributeOperation)

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
        index = @pendingWrites.map((o) => o.key).indexOf(field) # find failed operation
        @pendingWrites.splice(index, 1) if index > -1 # remove failing operation, otherwise the save() keeps on failing on this node
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
    @pendingWrites.push(Operation.Node(@).removeAttribute(currentAttribute.nodeId))

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

  peekPendingWrites: () ->
    @_collectPendingWrites(undefined, false)

  # Go through each relation and recursively add all pendingWrites per relation AND that of the objects
  _collectPendingWrites: (collected = [], cleanup=true) ->
    # Register to keep track which nodes have been collected to prevent recursive blowup
    collected.push(@) if @ not in collected
    operations = @pendingWrites
    if not operations?
      return []

    if cleanup
      @pendingWrites = []
      i.__pendingOpNode = @ for i in operations

    for key, relation of @_relations
      for node in relation.nodes when node not in collected
        collected.push(node)
        operations = operations.concat(node._collectPendingWrites(collected, cleanup))

      operations = operations.concat(relation.pendingWrites)

      for node in relation.relationNodes when node not in collected
          collected.push(node)
          operations = operations.concat(node._collectPendingWrites(collected, cleanup))

      if cleanup
        i.__pendingOpNode = relation for i in relation.pendingWrites
        relation.pendingWrites = []

    operations


  # Clear all pendingWrites, used for instance after saving or when loading a node
  _clearPendingWrites: ->
    @pendingWrites = []

    for key, relation of @_relations
      for id, node of relation.nodes
        node._clearPendingWrites() if node.isDirty()

      relation.pendingWrites = []

  _setStored: ->
    @_stored = true

    for key, relation of @_relations
      for id, node of relation.nodes
        node._setStored() if not node._stored
    @


  # Checks whether needs saving
  isDirty: ->
    @pendingWrites.length isnt 0


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
          i.__pendingOpNode.pendingWrites.unshift(i)

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
          i.__pendingOpNode.pendingWrites.unshift(i)

        Promise.reject(e)
      )
    )

  # Removes node, with the option to remove it unrecoverable
  destroy: (project, unrecoverableRemove = false) ->
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

# Export
module.exports = WeaverNode
