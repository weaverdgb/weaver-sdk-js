cuid           = require('cuid')
Weaver         = require('./Weaver')
WeaverRelation = require('./WeaverRelation')
Operation      = require('./Operation')
isArray        = require('./util').isArray

class WeaverNode

  # Node loading from server
  @load: (nodeId) ->
    coreManager = Weaver.getCoreManager()
    coreManager.getNode(nodeId).then((serverNode) ->

      # Create node and transfer attributes
      node = new WeaverNode(nodeId)
      node.createdOn = serverNode.createdOn

      # Make an tuple array of values to easily filter out relations and attributes
      tuples = ({key, value} for key, value of serverNode)

      # Add attributes
      attributes =  tuples.filter((t) ->
        not isArray(t.value) and t.key isnt 'createdOn' and t.key isnt 'id'
      )
      node.attributes[t.key] = t.value for t in attributes

      # Add relations
      relations = tuples.filter((t) -> isArray(t.value))

      for r in relations
        for n in r.value
          node.relation(r.key).add(WeaverNode.get(n.id))

      node.clearPendingWrites()
      node
    )


  # Node creating for in queries
  @get: (nodeId) ->
    node = new WeaverNode(nodeId)
    node.pendingWrites = []
    node

  constructor: (@nodeId) ->
    @destroyed  = false
    # Generate random id if not given
    @nodeId     = cuid() if not @nodeId?
    @attributes = {}                      # Store all attributes in this object
    @relations  = {}                      # Store all relations in this object

    # All operations that need to get saved
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
  relation: (key) ->
    @relations[key] = new WeaverRelation(@, key) if not @relations[key]?
    @relations[key]


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