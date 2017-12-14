cuid = require('cuid')
Operation = require('./Operation')
Weaver  = require('./Weaver')

class WeaverRelation

  constructor: (@parent, @key, graph) ->
    @pendingWrites = []   # All operations that need to get saved
    @nodes = {}           # All nodes that this relation points to
    @relationNodes = {}   # Map node id to RelationNode
    @graph = graph if graph?

  _getNodeKey: (id, graph) ->
    "#{id}-#{graph}"

  load: ->
    new Weaver.Query().hasRelationIn(@key, @parent).find()
      .then((nodes) =>
        @nodes[@_getNodeKey(node.id(), node.graph)] = node for node in nodes
        @nodes
      )

  query: ->
    Promise.resolve([])


  to: (node)->
    throw new Error("No relation to a node with this id: #{node.id()}") if not @relationNodes[@_getNodeKey(node.id(), node.graph)]
    Weaver.RelationNode.load(@relationNodes[@_getNodeKey(node.id(), node.graph)].id(), null, Weaver.RelationNode, true)

  all: ->
    (node for key, node of @nodes)

  first: ->
    @.all()[0]

  add: (node, relId, addToPendingWrites = true) ->
    relId = cuid() if not relId?
    @nodes[@_getNodeKey(node.id(), node.graph)] = node

    # Currently this assumes having one relation to the same node
    # it should change, but its here now for backwards compatibility
    @relationNodes[@_getNodeKey(node.id(), node.graph)] = Weaver.RelationNode.get(relId, Weaver.RelationNode)

    Weaver.publish("node.relation.add", {node: @parent, key: @key, target: node})
    @pendingWrites.push(Operation.Node(@parent).createRelation(@key, node, relId))

  update: (oldNode, newNode) ->
    newRelId = cuid()
    oldRel = @relationNodes[@_getNodeKey(oldNode.id(), oldNode.graph)]

    delete @nodes[@_getNodeKey(oldNode.id(), oldNode.graph)]
    @nodes[@_getNodeKey(newNode.id(), newNode.graph)] = newNode

    delete @relationNodes[@_getNodeKey(oldNode.id(), oldNode.graph)]
    @relationNodes[@_getNodeKey(newNode.id(), newNode.graph)] = Weaver.RelationNode.get(newRelId, Weaver.RelationNode)

    Weaver.publish("node.relation.update", {node: @parent, key: @key, oldTarget: oldNode, target: newNode})
    @pendingWrites.push(Operation.Node(@parent).createRelation(@key, newNode, newRelId, oldRel, Weaver.getInstance()._ignoresOutOfDate))

  remove: (node) ->
    # TODO: This failes when relation is not saved, should be able to only remove locally
    @relationNodes[@_getNodeKey(node.id(), node.graph)].destroy()

    # Deprecate this write operation
    #relId = @relationNodes[node.id()].id()
    #@pendingWrites.push(Operation.Node(@parent).removeRelation(relId))
    Weaver.publish("node.relation.remove", {node: @parent, key: @key, target: node})

    delete @nodes[@_getNodeKey(node.id(), node.graph)]
    delete @relationNodes[@_getNodeKey(node.id(), node.graph)]


# Export
module.exports  = WeaverRelation
