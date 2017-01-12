cuid           = require('cuid')
Weaver         = require('./Weaver')
WeaverRelation = require('./WeaverRelation')
Operation      = require('./Operation')
isArray        = require('./util').isArray

class WeaverNode

  constructor: (@nodeId) ->
    # Generate random id if not given
    @nodeId     = cuid() if not @nodeId?

    # Store all attributes and relations in these objects
    @attributes = {}
    @relations  = {}

    # All operations that need to get saved
    @pendingWrites = [Operation.Node(@).create()]


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

      # Clear all currently made pending writes since node is loaded of server
      node.clearPendingWrites()
      node
    )


  # Node creating for in queries
  @get: (nodeId) ->
    node = new WeaverNode(nodeId)
    node.pendingWrites = []
    node


  # Return id
  id: ->
    @nodeId


  # Gets attributes
  get: (field) ->
    @attributes[field]


  # Update attribute
  set: (field, value) ->
    @attributes[field] = value

    # Save change as pending
    @pendingWrites.push(Operation.Node(@).setAttribute(field, value))


  # Remove attribute
  unset: (field) ->
    delete @attributes[field]

    # Save change as pending
    @pendingWrites.push(Operation.Node(@).unsetAttribute(field))


  # Create a new Relation
  relation: (key) ->
    @relations[key] = new WeaverRelation(@, key) if not @relations[key]?
    @relations[key]


  # Go through each relation and recursively add all pendingWrites per relation AND that of the objects
  collectPendingWrites: (collected) ->
    # Register to keep track which nodes have been collected to prevent recursive blowup
    collected  = {} if not collected?
    operations = @pendingWrites

    for key, relation of @relations
      for id, node of relation.nodes
        if not collected[node.id()]
          collected[node.id()] = true
          operations = operations.concat(node.collectPendingWrites(collected))

      operations = operations.concat(relation.pendingWrites)

    operations


  # Clear all pendingWrites, used for instance after saving or when loading a node
  clearPendingWrites: ->
    @pendingWrites = []

    for key, relation of @relations
      for id, node of relation.nodes
        node.clearPendingWrites() if node.isDirty()

      relation.pendingWrites = []


  # Checks whether needs saving
  isDirty: ->
    @pendingWrites.length isnt 0


  # Save node and all values / relations and relation objects to server
  save: (values) ->
    coreManager = Weaver.getCoreManager()
    coreManager.executeOperations(@collectPendingWrites()).then(=>
      @clearPendingWrites()
      @
    )


  # Removes node
  destroy: ->
    coreManager = Weaver.getCoreManager()
    coreManager.executeOperations([Operation.Node(@).destroy()]).then(=>
      @destroyed = true
      @saved = false
      undefined
    )


# Export
Weaver.Node    = WeaverNode
module.exports = WeaverNode