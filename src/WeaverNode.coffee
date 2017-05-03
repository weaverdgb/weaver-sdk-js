cuid        = require('cuid')
Operation   = require('./Operation')
WeaverRoot  = require('./WeaverRoot')

class WeaverNode extends WeaverRoot

  getClass: ->
    WeaverNode
  @getClass: ->
    WeaverNode

  constructor: (@nodeId) ->
    # Generate random id if not given
    @nodeId = cuid() if not @nodeId?
    @_stored = false       # if true, available in database, local node can hold unsaved changes
    @_loaded = false       # if true, all information from the database was localised on construction

    # Store all attributes and relations in these objects
    @attributes = {}
    @relations  = {}

    # All operations that need to get saved
    @pendingWrites = [Operation.Node(@).create()]


  # Node loading from server
  @load: (nodeId, target, Constructor) ->
    Constructor = WeaverNode if not Constructor?
    Weaver = @getWeaverClass()
    new Weaver.Query(target).get(nodeId, Constructor)

  _loadFromQuery: (object, Constructor) ->
    Constructor = Constructor or WeaverNode
    @attributes = object.attributes

    for key, targetNodes of object.relations
      for node in targetNodes
        instance = new Constructor(node.nodeId)
        instance._loadFromQuery(node, Constructor)
        relId = object.relationNodeIds[key][node.nodeId]
        @relation(key).add(instance, relId)

    @._clearPendingWrites()
    @


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
    @attributes[field]


  # Update attribute
  set: (field, value) ->
    if @attributes[field]?
      @attributes[field] = value
      @pendingWrites.push(Operation.Node(@).updateAttribute(field, value))

    else
      @attributes[field] = value
      @pendingWrites.push(Operation.Node(@).setAttribute(field, value))

    @


  # Update attribute by incrementing the value, the result depends on concurrent requests, so check the result
  increment: (field, value, project) ->

    if not @attributes[field]?
      throw new Error
    if typeof value isnt 'number'
      throw new Error

    operation = Operation.Node(@).incrementAttribute(field, value)
    @getWeaver().getCoreManager().executeOperations([operation], project).then((res)=>
      if res? and res.incrementedTo?
        @attributes[field] = res.incrementedTo
        res.incrementedTo
    )


  # Remove attribute
  unset: (field) ->
    delete @attributes[field]

    # Save change as pending
    @pendingWrites.push(Operation.Node(@).unsetAttribute(field))
    @


  # Create a new Relation
  relation: (key) ->
    Weaver = @getWeaverClass()
    @relations[key] = new Weaver.Relation(@, key) if not @relations[key]?
    @relations[key]


  clone: (keyMap, caller) ->
    clone = new WeaverNode()
    clone.set(field, value) for field, value of @attributes
    self = @
    for key, rel of @relations
      for id, node of rel.nodes
        if keyMap[key]?
          Constructor = keyMap[key]
          Constructor.load(id).then((node)->
            node.clone({}, self).then((node)->
              clone.relation(key).add(node)
              Promise.resolve(clone)
            )
          )
        else
          clone.relation(key).add(node)
          Promise.resolve(clone)


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
    @getWeaver().getCoreManager().executeOperations(@_collectPendingWrites(), project).then(=>
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

    @getWeaver().getCoreManager().executeOperations(operations, project).then(
      for node in array
        node._setStored()
      array
    )


  # Removes node
  destroy: (project) ->
    @getWeaver().getCoreManager().executeOperations([Operation.Node(@).destroy()], project).then(=>
      delete @[key] for key of @
      undefined
    )

  # TODO: Implement
  setACL: (acl) ->
    return


# Export
module.exports = WeaverNode
