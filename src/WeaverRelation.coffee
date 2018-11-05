cuid        = require('cuid')
Operation   = require('./Operation')
Weaver      = require('./Weaver')
Promise     = require('bluebird')

class WeaverRelation

  constructor: (@owner, @key) ->
    @pendingWrites = []                    # All operations that need to get saved
    @nodes = new Weaver.NodeList()         # All nodes that this relation points to
    @relationNodes = new Weaver.NodeList() # RelationNodes

  _removeNode: (oldNode) ->
    @nodes = @nodes.filter((x) -> not x.equals(oldNode))

  _replaceNode: (oldNode, newNode) ->
    @_removeNode(oldNode)
    @_addNodes(newNode)

  _addNodes: (nodes...) ->
    for node in nodes
      if @nodes.find((x) -> x.equals(node))?
        @_removeNode(node)
      @nodes.push(node)

  _getRelationNodeForTarget: (node) ->
    (i for i in @relationNodes when i.to().equals(node))[0] or undefined

  _removeRelationNodeForTarget: (oldNode) ->
    @relationNodes = @relationNodes.filter((x) -> not x.to().equals(oldNode))

  load: (constructor)->
    new Weaver.Query()
    .hasRelationIn(@key, @owner)
    .selectRelations(@key)
    .find(constructor)
    .then((nodes)=>
      Promise.map(nodes, (node)->node.load())
      .then(=>
        @_addNodes(nodes...)
        @nodes
      )
    )

  query: ->
    Promise.resolve([])

  to: (node)->
    relNode = @_getRelationNodeForTarget(node)
    throw new Error("No relation to a node with this id: #{node.id()}") if not relNode?
    Weaver.RelationNode.load(relNode.id(), null, Weaver.RelationNode, true, false, relNode.getGraph())

  all: ->
    @nodes

  first: ->
    @.all()[0]

  addInGraph: (node, graph) ->
    @add(node, undefined, true, graph)

  _createRelationNode: (relId, targetNode, graph) ->
    result = Weaver.RelationNode.get(relId, Weaver.RelationNode, graph)
    result.fromNode = @owner
    result.toNode = targetNode
    result

  add: (node, relId, addToPendingWrites = true, graph) ->
    relId ?= cuid()
    graph ?= @owner.getGraph()
    @_addNodes(node)

    # Currently this assumes having one relation to the same node
    # it should change, but its here now for backwards compatibility
    relationNode = @_createRelationNode(relId, node, graph)
    @relationNodes.push(relationNode)

    Weaver.publish("node.relation.add", {node: @owner, key: @key, target: node})
    @pendingWrites.push(Operation.Node(@owner).createRelation(@key, node, relId, undefined, false, graph)) if addToPendingWrites
    relationNode

  update: (oldNode, newNode) ->
    newRelId = cuid()
    oldRel = @_getRelationNodeForTarget(oldNode)

    @_replaceNode(oldNode, newNode)

    @_removeRelationNodeForTarget(oldNode)
    @relationNodes.push(@_createRelationNode(newRelId, newNode))

    Weaver.publish("node.relation.update", {node: @owner, key: @key, oldTarget: oldNode, target: newNode})
    @pendingWrites.push(Operation.Node(@owner).createRelation(@key, newNode, newRelId, oldRel, Weaver.getInstance()._ignoresOutOfDate))

  remove: (node) ->
    # TODO: This failes when relation is not saved, should be able to only remove locally
    relNode = @_getRelationNodeForTarget(node)
    @_removeRelationNodeForTarget(node)
    @_removeNode(node)
    Weaver.publish("node.relation.remove", {node: @owner, key: @key, target: node})
    relNode.destroy()

  only: (node) ->
    Promise.map(@nodes, (existing)=>
      @remove(existing) if !existing.equals(node)
    ).then(=>
      @add(node) if @nodes.length is 0
      @owner.save()
    )

# Export
module.exports  = WeaverRelation
