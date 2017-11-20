cuid = require('cuid')
Operation = require('./Operation')
Weaver  = require('./Weaver')

class WeaverRelation

  constructor: (@parent, @key) ->
    @pendingWrites = []   # All operations that need to get saved
    @nodes = {}           # All nodes that this relation points to
    @relationNodes = {}   # Map node id to RelationNode

  load: ->
    new Weaver.Query().hasRelationIn(@key, @parent).find()
      .then((nodes) =>
        @nodes[node.id()] = node for node in nodes
        @nodes
      )

  query: ->
    Promise.resolve([])


  to: (node)->
    throw new Error("No relation to a node with this id: #{node.id()}") if not @relationNodes[node.id()]
    Weaver.RelationNode.load(@relationNodes[node.id()].id(), null, Weaver.RelationNode, true)

  all: ->
    (node for key, node of @nodes)

  first: ->
    @.all()[0]

  add: (node, relId, addToPendingWrites = true) ->
    relId = cuid() if not relId?
    @nodes[node.id()] = node

    # Currently this assumes having one relation to the same node
    # it should change, but its here now for backwards compatibility
    @relationNodes[node.id()] = Weaver.RelationNode.get(relId, Weaver.RelationNode)

    Weaver.publish("node.relation.add", {node: @parent, key: @key, target: node})
    @pendingWrites.push(Operation.Node(@parent).createRelation(@key, node.id(), relId))

  update: (oldNode, newNode) ->
    newRelId = cuid()
    oldRelId = @relationNodes[oldNode.id()].id()

    delete @nodes[oldNode.id()]
    @nodes[newNode.id()] = newNode

    delete @relationNodes[oldNode.id()]
    @relationNodes[newNode.id()] = Weaver.RelationNode.get(newRelId, Weaver.RelationNode)

    Weaver.publish("node.relation.update", {node: @parent, key: @key, oldTarget: oldNode, target: newNode})
    @pendingWrites.push(Operation.Node(@parent).createRelation(@key, newNode.id(), newRelId, oldRelId, Weaver.getInstance()._ignoresOutOfDate))


  remove: (node) ->
    # TODO: This failes when relation is not saved, should be able to only remove locally
    @relationNodes[node.id()].destroy()

    # Deprecate this write operation
    #relId = @relationNodes[node.id()].id()
    #@pendingWrites.push(Operation.Node(@parent).removeRelation(relId))
    Weaver.publish("node.relation.remove", {node: @parent, key: @key, target: node})

    delete @nodes[node.id()]
    delete @relationNodes[node.id()]


# Export
module.exports  = WeaverRelation
