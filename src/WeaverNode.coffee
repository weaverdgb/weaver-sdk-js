# Libs
cuid   = require('cuid')
Weaver = require('./Weaver')

console.log(Weaver)

module.exports =
class WeaverNode

  # Static node loading
  @get: (nodeId) ->
    node = new WeaverNode()
    node.nodeId = nodeId
    node

  constructor: () ->
    @saved   = false      # Should create this node on the server with the first save
    @nodeId = cuid()      # Generate random id
    @attributes = {}      # Store all attributes in this object
    @relations  = {}      # Store all relations in this object

    # All operations that need to get saved
    @pendingSets = {}


  get: (field) ->
    @attributes[field]


  set: (field, value) ->
    # Save change as pending
    @pendingSets[field] = value

    # Update attribute
    @attributes[field] = value


  unset: (field) ->
    # Save change as null in pending
    @pendingSets[field] = null

    # Update attribute
    delete @attributes[field]


  relation: (name) ->
    new WeaverRelation(this, name)


  save: (values) ->
    console.log(Weaver)

    coreManager = Weaver.getCoreManager()

    # These update operations will be sent to the server
    operations = []

    # Check to create the node first
    if not @saved?
      operations.push(coreManager.createNodeOperation(@))
      @saved = true

    # Go through all pendingSets
    for attribute, value of @pendingSets
      if value is null
        operations.push(coreManager.unsetAttributeOperation(attribute, @))
      else
        operations.push(coreManager.setAttributeOperation(attribute, value, @))

    coreManager.executeOperations(operations)


  destroy: ->


  fetch: ->
