cuid           = require('cuid')
Weaver         = require('./Weaver')
WeaverRelation = require('./WeaverRelation')
Operation      = require('./Operation')

class WeaverNode

  # Node loading from server
  @load: (nodeId) ->
    coreManager = Weaver.getCoreManager()
    coreManager.getNode(nodeId).then((serverNode) ->
      #console.log(serverNode)

      # Create node and transfer attributes
      node = new WeaverNode(nodeId)
      node.pendingWrites = []
      node.created =  serverNode.created

      # Add attributes

      # Add relations

      node
    )


  # Node creating for in queries
  @get: (nodeId) ->
    node = new WeaverNode(nodeId)
    node.pendingWrites = []
    node

  constructor: (@nodeId) ->
    @destroyed  = false
    @nodeId     = cuid() if not @nodeId?  # Generate random id if not given
    @attributes = {}                      # Store all attributes in this object
    @relations  = {}                      # Store all relations in this object
    @pendingWrites = []                   # All operations that need to get saved
    @pendingWrites = [Operation.Node(@).create()]

  id: ->
    @nodeId

  # Gets both attributes as well as relations
  get: (field) ->
    @attributes[field]


  set: (field, value) ->
    # Save change as pending
    @pendingWrites.push(Operation.Node(@).setAttribute(field, value))

    # Update attribute
    @attributes[field] = value


  unset: (field) ->
    @pendingWrites.push(Operation.Node(@).unsetAttribute(field))

    # Update attribute
    delete @attributes[field]


  # Create a new Relation
  relation: (name) ->
    @relations[name] = new WeaverRelation(this, name) if not @relations[name]?
    @relations[name]




  # Go through each relation and recursively add all pendingWrites per relation AND that of the objects
  collectPendingWrites: ->
    operations = @pendingWrites

    for key, relation of @relations
      for id, node of relation.nodes
        operations = operations.concat(node.collectPendingWrites())

      operations = operations.concat(relation.pendingWrites)

    operations

  clearPendingWrites: ->
    @pendingWrites = []

    for key, relation of @relations
      for id, node of relation.nodes
        node.clearPendingWrites()

      relation.pendingWrites = []


  isDirty: ->
    @pendingWrites isnt []

  save: (values) ->
    coreManager = Weaver.getCoreManager()

    coreManager.executeOperations(@collectPendingWrites()).then(=>
      @clearPendingWrites()
      @
    )


  destroy: ->
    coreManager = Weaver.getCoreManager()
    coreManager.executeOperations([Operation.Node(@).destroy()]).then(=>
      @destroyed = true
      @saved = false
      undefined
    )

  fetch: ->


# Export
Weaver.Node    = WeaverNode
module.exports = WeaverNode