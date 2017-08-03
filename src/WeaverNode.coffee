cuid        = require('cuid')
Operation   = require('./Operation')
Weaver      = require('./Weaver')
util        = require('./util')

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
  @load: (nodeId, target, Constructor) ->
    Constructor = WeaverNode if not Constructor?
    new Weaver.Query(target).get(nodeId, Constructor)

  _loadFromQuery: (object, Constructor) ->
    Constructor = Constructor or WeaverNode
    @attributes = object.attributes

    for key, relations of object.relations
      for relation in relations
        instance = new Constructor(relation.target.nodeId)
        instance._loadFromQuery(relation.target, Constructor)
        @relation(key).add(instance, relation.nodeId)

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


  # Return id
  id: ->
    @nodeId


  # Gets attributes
  get: (field) ->
    fieldArray = @attributes[field]

    if not fieldArray? or fieldArray.length is 0
      return undefined
    else if fieldArray.length is 1
      return fieldArray[0].value    # Returning value and not full object to be backwards compatible
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


  clone: (keyMap) ->
    keyMap = keyMap or {}
    clone = new WeaverNode()
    clone.set(field, value) for field, value of @attributes when field isnt 'createdOn'
    self = @
    for key, rel of @relations
      for id, node of rel.nodes
        if keyMap[key]?
          Constructor = keyMap[key]
          Constructor.load(id).then((node)->
            node.clone({}, self).then((node)->
              clone.relation(key).add(node)
              return Promise.resolve(clone)
            )
          )
        else
          clone.relation(key).add(node)

    return Promise.resolve(clone)



  # Go through each relation and recursively add all pendingWrites per relation AND that of the objects
  _collectPendingWrites: (collected) ->
    # Register to keep track which nodes have been collected to prevent recursive blowup
    collected  = {} if not collected?
    collected[@id()] = true
    operations = @pendingWrites

    for key, relation of @relations
      for id, node of relation.nodes
        if not collected[node.id()]
          collected[node.id()] = true
          operations = operations.concat(node._collectPendingWrites(collected))

      operations = operations.concat(relation.pendingWrites)
    operations


  # Clear all pendingWrites, used for instance after saving or when loading a node
  _clearPendingWrites: ->
    @pendingWrites = []

    for key, relation of @relations
      for id, node of relation.nodes
        node._clearPendingWrites() if node.isDirty()

      relation.pendingWrites = []
    @


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
    Weaver.getCoreManager().executeOperations(@_collectPendingWrites(), project).then(=>
      @_clearPendingWrites()
      @_setStored()
      @
    )

  # Save everything related to all the nodes in the array in one database call
  # No checking for overlapping elements in linked network per element
  @batchSave: (array, project) ->
    operations = []
    for node in array
      operations = operations.concat(node._collectPendingWrites())
      node._clearPendingWrites()

    Weaver.getCoreManager().executeOperations(operations, project).then(
      for node in array
        node._setStored()
      array
    )


  # Removes node
  destroy: (project) ->
    Weaver.getCoreManager().executeOperations([Operation.Node(@).removeNode()], project).then(=>
      delete @[key] for key of @
      undefined
    )

  # TODO: Implement
  setACL: (acl) ->
    return


# Export
module.exports = WeaverNode
