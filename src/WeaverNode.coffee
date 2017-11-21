cuid        = require('cuid')
Operation   = require('./Operation')
Weaver      = require('./Weaver')
util        = require('./util')
_           = require('lodash')
Promise     = require('bluebird')
WeaverError = require('./WeaverError')

class WeaverNode

  constructor: (@nodeId) ->
    # Generate random id if not given
    @nodeId = cuid() if not @nodeId?
    @_stored = false       # if true, available in database, local node can hold unsaved changes
    @_loaded = false       # if true, all information from the database was localised on construction
    # Store all attributes and relations in these objects
    @attributes = {}
    @relations  = {}

    # All operations that need to get saved
    @pendingWrites = [Operation.Node(@).createNode()]

    Weaver.publish('node.created', @)

  # Node loading from server
  @load: (nodeId, target, Constructor, includeRelations = false, includeAttributes = false) ->
    if !nodeId?
      Promise.reject("Cannot load nodes with an undefined id")
    else
      Constructor = WeaverNode if not Constructor?
      query = new Weaver.Query(target)
      query.withRelations() if includeRelations
      query.withAttributes() if includeAttributes
      query.get(nodeId, Constructor)


  @loadFromQuery: (node, constructorFunction, fullyLoaded = true) ->
    if constructorFunction?
      Constructor = constructorFunction(Weaver.Node.loadFromQuery(node)) or Weaver.Node
    else
      Constructor = Weaver.Node

    instance = new Constructor(node.nodeId)
    instance._loadFromQuery(node, constructorFunction, fullyLoaded)
    instance._setStored()
    instance

  _loadFromQuery: (object, constructorFunction, fullyLoaded = true) ->
    @attributes = object.attributes
    @_loaded    = object.creator? && fullyLoaded

    for key, relations of object.relations
      for relation in relations

        if constructorFunction?
          Constructor = constructorFunction(Weaver.Node.loadFromQuery(relation.target)) or Weaver.Node
        else
          Constructor = Weaver.Node

        instance = new Constructor(relation.target.nodeId)
        instance._loadFromQuery(relation.target, constructorFunction, fullyLoaded)
        @relation(key).add(instance, relation.nodeId, false)

    @._clearPendingWrites()
    Weaver.publish('node.loaded', @)
    @

  # Loads current node
  load: ->
    Weaver.Node.load(@nodeId).then((loadedNode) =>
      @[key] = value for key, value of loadedNode
      @
    )

  # Node creating for in queries
  @get: (nodeId, Constructor) ->
    Constructor = WeaverNode if not Constructor?
    node = new Constructor(nodeId)
    node._clearPendingWrites()
    node

  @firstOrCreate: (nodeId, Constructor) ->
    new Weaver.Query()
      .get(nodeId, Constructor)
      .catch(->
        Constructor = WeaverNode if not Constructor?
        new Constructor(nodeId).save()
      )

  # Return id
  id: ->
    @nodeId


  # Gets attributes
  get: (field) ->
    fieldArray = @attributes[field]

    if not fieldArray? or fieldArray.length is 0
      return undefined
    else if fieldArray.length is 1
      attribute = fieldArray[0]

      if attribute.dataType is 'date'
        return new Date(attribute.value)
      else
        return attribute.value    # Returning value and not full object to be backwards compatible
    else
      return fieldArray



  set: (field, value, dataType, options) ->
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
    }

    if @attributes[field]?
      if @attributes[field].length > 1
        throw new Error("Specifiy which attribute to set, more than 1 found for " + field) # TODO: Support later

      oldAttribute = @attributes[field][0]
      eventData.oldValue = oldAttribute.value

      eventMsg += '.update'
      newAttributeOperation = Operation.Node(@).createAttribute(field, value, dataType, oldAttribute.nodeId, Weaver.getInstance()._ignoresOutOfDate if !options?.ignoresOutOfDate?)
    else
      eventMsg += '.set'
      newAttributeOperation = Operation.Node(@).createAttribute(field, value, dataType)

    newAttribute = {
      nodeId: newAttributeOperation.id
      dataType
      value
      key: field
      created: newAttributeOperation.timestamp
      attributes: {}
      relations: {}
    }

    @attributes[field] = [newAttribute]
    Weaver.publish(eventMsg, eventData)
    @pendingWrites.push(newAttributeOperation)

    return @


  # Update attribute by incrementing the value, the result depends on concurrent requests, so check the result
  increment: (field, value = 1, project) ->
    Weaver.getInstance()._ignoresOutOfDate = false
    if not @attributes[field]?
      throw new Error("There is no field " + field + " to increment")
    if typeof value isnt 'number'
      throw new Error("Field " + field + " is not a number")

    currentValue = @get(field)
    pendingNewValue = currentValue + value
    @set(field, pendingNewValue)

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
        Promise.reject()
    )

  _incrementOfOutSync: (field, value, project) ->

    new Weaver.Query()
    .select(field)
    .restrict(@id())
    .first()
    .then((loadedNode) =>
      currentValue = loadedNode.get(field)
      pendingNewValue = currentValue + value
      loadedNode.set(field, pendingNewValue)

      # To be backwards compatible, but its better not to save here
      loadedNode.save().then(->
        # Return the incremented value
        pendingNewValue
      )
    )


  # Remove attribute
  unset: (field) ->
    if not @attributes[field]?
      throw new Error("There is no field " + field + " to unset")

    if @attributes[field].length > 1
      throw new Error("Currently not possible to unset is multiple attributes are present")

    currentAttribute = @attributes[field][0]

    # Save change as pending
    @pendingWrites.push(Operation.Node(@).removeAttribute(currentAttribute.nodeId))

    Weaver.publish('node.attribute.unset', {node: @, field})

    # Unset locally
    delete @attributes[field]
    @


  # Create a new Relation
  relation: (key, Constructor = Weaver.Relation) ->
    @relations[key] = new Constructor(@, key) if not @relations[key]?
    @relations[key]


  clone: (newId, relationTraversal...) ->
    cm = Weaver.getCoreManager()
    cm.cloneNode(@nodeId, newId, relationTraversal)

  peekPendingWrites: (collected) ->

    # Register to keep track which nodes have been collected to prevent recursive blowup
    collected  = {} if not collected?
    collected[@id()] = true
    operations = @pendingWrites

    for key, relation of @relations
      for id, node of relation.nodes
        if not collected[node.id()]
          collected[node.id()] = true
          operations = operations.concat(node.peekPendingWrites(collected))

      operations = operations.concat(relation.pendingWrites)

    for operation in operations
      delete operation[field] for field, value of operation when not value?

    operations



  # Go through each relation and recursively add all pendingWrites per relation AND that of the objects
  _collectPendingWrites: (collected) ->
    # Register to keep track which nodes have been collected to prevent recursive blowup
    collected  = {} if not collected?
    collected[@id()] = true
    operations = @pendingWrites
    @pendingWrites = []

    i.__pendingOpNode = @ for i in operations

    for key, relation of @relations
      for id, node of relation.nodes
        if node.id()? and not collected[node.id()]
          collected[node.id()] = true
          operations = operations.concat(node._collectPendingWrites(collected))

      i.__pendingOpNode = relation for i in relation.pendingWrites
      operations = operations.concat(relation.pendingWrites)
      relation.pendingWrites = []
    operations


  # Clear all pendingWrites, used for instance after saving or when loading a node
  _clearPendingWrites: ->
    @pendingWrites = []

    for key, relation of @relations
      for id, node of relation.nodes
        node._clearPendingWrites() if node.isDirty()

      relation.pendingWrites = []

  _setStored: ->
    @_stored = true

    for key, relation of @relations
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


# Export
module.exports = WeaverNode
