# Libs
cuid      = require('cuid')
Weaver    = require('./Weaver')
Operation = require('./Operation')

class WeaverNode

  # Static node loading
  @get: (nodeId) ->
    node = new WeaverNode()
    node.nodeId = nodeId
    node

  constructor: (@nodeId) ->
    @saved  = false                  # Should create this node on the server with the first save
    @nodeId = cuid() if not @nodeId? # Generate random id if not given
    @attributes = {}                 # Store all attributes in this object
    @relations  = {}                 # Store all relations in this object

    # All operations that need to get saved
    @pendingWrites = {}


  id: ->
    @nodeId

  get: (field) ->
    @attributes[field]


  set: (field, value) ->
    # Save change as pending
    @pendingWrites[field] = value

    # Update attribute
    @attributes[field] = value


  unset: (field) ->
    # Save change as null in pending
    @pendingWrites[field] = null

    # Update attribute
    delete @attributes[field]


  relation: (name) ->
    new WeaverRelation(this, name)


  save: (values) ->
    coreManager = Weaver.getCoreManager()

    # These update operations will be sent to the server
    operations = []

    # Check to create the node first
    if not @saved
      operations.push(new Operation.Node(@).create())
      @saved = true

    # Go through all pendingWrites
    for attribute, value of @pendingWrites
      if value is null
        operations.push(new Operation.Node(@).unsetAttribute(attribute))
      else
        operations.push(new Operation.Node(@).setAttribute(attribute, value))

    coreManager.executeOperations(operations).then(=> @)


  destroy: ->


  fetch: ->


# Export
Weaver.Node    = WeaverNode
module.exports = WeaverNode