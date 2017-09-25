cuid        = require('cuid')
Operation   = require('./Operation')
Weaver      = require('./Weaver')
util        = require('./util')
_           = require('lodash')

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


  # Node loading from server
  @load: (nodeId, target, Constructor, includeRelations = false, includeAttributes = false) ->
    Constructor = WeaverNode if not Constructor?
    query = new Weaver.Query(target)
    query.withRelations() if includeRelations
    query.withAttributes() if includeAttributes
    query.get(nodeId, Constructor)


  @loadFromQuery: (node, constructorFunction) ->
    if constructorFunction?
      Constructor = constructorFunction(Weaver.Node.loadFromQuery(node)) or Weaver.Node
    else
      Constructor = Weaver.Node

    instance = new Constructor(node.nodeId)
    instance._loadFromQuery(node, constructorFunction)
    instance._setStored()
    instance._loaded = true
    instance


  _loadFromQuery: (object, constructorFunction) ->
    @attributes = object.attributes

    for key, relations of object.relations
      for relation in relations

        if constructorFunction?
          Constructor = constructorFunction(Weaver.Node.loadFromQuery(relation.target)) or Weaver.Node
        else
          Constructor = Weaver.Node

        instance = new Constructor(relation.target.nodeId)
        instance._loadFromQuery(relation.target, constructorFunction)
        @relation(key).add(instance, relation.nodeId, false)

    @._clearPendingWrites()
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



  # Update attribute
  set: (field, value) ->
    # Get attribute datatype, TODO: Support date
    dataType = null
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

    if @attributes[field]?
      if @attributes[field].length > 1
        throw new Error("Specifiy which attribute to set, more than 1 found for " + field) # TODO: Support later

      oldAttribute = @attributes[field][0]
      newAttributeOperation = Operation.Node(@).createAttribute(field, value, dataType, oldAttribute.nodeId)

    else
      newAttributeOperation = Operation.Node(@).createAttribute(field, value, dataType)

    newAttribute = {
      nodeId: newAttributeOperation.id
      dataType
      value
      key: field
      creator: Weaver.instance.currentUser().userId,
      created: newAttributeOperation.timestamp
      attributes: {}
      relations: {}
    }

    @attributes[field] = [newAttribute]
    @pendingWrites.push(newAttributeOperation)

    return @


  # Update attribute by incrementing the value, the result depends on concurrent requests, so check the result
  increment: (field, value, project) ->

    if not @attributes[field]?
      throw new Error("There is no field " + field + " to increment")
    if typeof value isnt 'number'
      throw new Error("Field " + field + " is not a number")

    currentValue = @get(field)
    @set(field, currentValue + value)

    # To be backwards compatible, but its better not to save here
    @save().then(->
      # Return the incremented value
      currentValue + value
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

    # Unset locally
    delete @attributes[field]
    @


  # Create a new Relation
  relation: (key) ->
    @relations[key] = new Weaver.Relation(@, key) if not @relations[key]?
    @relations[key]


  clone: (newId, relationTraversal...) ->
    cm = Weaver.getCoreManager()
    cm.cloneNode(@nodeId, newId, relationTraversal)


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
        if not collected[node.id()]
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

    sp = cm.operationsQueue.then(=>
      writes = @_collectPendingWrites()

      cm.executeOperations((_.omit(i, "__pendingOpNode") for i in writes), project).then(=>
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

    new Promise((resultResolve, resultReject) =>
      cm.operationsQueue = new Promise((resolve) =>
        sp.then((r)->
          resolve()
          resultResolve(r)
        ).catch((e) ->
          resolve()
          resultReject(e)
        )
      )
    )


  @batchSave: (array, project) ->
    Promise.all(i.save(project) for i in array)

  # Removes node
  destroy: (project) ->
    cm = Weaver.getCoreManager()
    rm = cm.operationsQueue.then( =>
      if @nodeId?
        cm.executeOperations([Operation.Node(@).removeNode()], project).then(=>
          delete @[key] for key of @
          undefined
        )
      else
        undefined
    )

    new Promise((resultResolve, resultReject) =>
      cm.operationsQueue = new Promise((resolve) =>
        rm.then((r)->
          resolve()
          resultResolve(r)
        ).catch((e) ->
          resolve()
          resultReject(e)
        )
      )
    )
  # TODO: Implement
  setACL: (acl) ->
    return


# Export
module.exports = WeaverNode
