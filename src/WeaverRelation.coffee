cuid        = require('cuid')
Operation   = require('./Operation')
Weaver      = require('./Weaver')
Promise     = require('bluebird')

class WeaverRelation

  constructor: (@owner, @key) ->
    @pendingWrites = []                    # All operations that need to get saved
    @nodes = new Weaver.NodeList()         # All nodes that this relation points to
    @relationNodes = new Weaver.NodeList() # RelationNodes

  _removeRelationNode: (relNode) ->
    i = 0
    while i < @relationNodes.length
      node = @relationNodes[i]
      if node.equals(relNode)
        @nodes.splice(i, 1)
        @relationNodes.splice(i, 1)
      else
        i++

  _getRelationNodesForTarget: (node) ->
    (i for i in @relationNodes when i.to().equals(node))

  _getNodeForRelationNode: (relNode) ->
    return @nodes[i] if node.equals(relNode) for node, i in @relationNodes
      

  load: ()->
    new Weaver.Query()
    .restrict(@owner)
    .selectOut(@key)
    .selectRelations(@key)
    .find()
    .then((nodes)=>
      reloadedRelation = nodes[0].relation(@key)
      @nodes         = reloadedRelation.nodes
      @relationNodes = reloadedRelation.relationNodes
    )

  query: ->
    Promise.resolve([])

  to: (node)->
    relNode = @_getRelationNodesForTarget(node)[0]
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
    @nodes.push(node)

    # Currently this assumes having one relation to the same node
    # it should change, but its here now for backwards compatibility
    relationNode = @_createRelationNode(relId, node, graph)
    @relationNodes.push(relationNode)

    Weaver.publish("node.relation.add", {node: @owner, key: @key, target: node})
    @pendingWrites.push(Operation.Node(@owner).createRelation(@key, node, relId, undefined, false, graph)) if addToPendingWrites
    relationNode

  update: (oldNode, newNode) ->
    newRelId = cuid()
    oldRel = @_getRelationNodesForTarget(oldNode)[0]

    @_removeRelationNode(oldRel)
    @nodes.push(newNode)

    @relationNodes.push(@_createRelationNode(newRelId, newNode))

    Weaver.publish("node.relation.update", {node: @owner, key: @key, oldTarget: oldNode, target: newNode})
    @pendingWrites.push(Operation.Node(@owner).createRelation(@key, newNode, newRelId, oldRel, Weaver.getInstance()._ignoresOutOfDate))

  remove: (node) ->
    # TODO: This failes when relation is not saved, should be able to only remove locally
    Promise.map(@_getRelationNodesForTarget(node), (relNode)=>
      @_removeRelationNode(relNode)
      relNode.destroy()
    ).then(=>
      Weaver.publish("node.relation.remove", {node: @owner, key: @key, target: node})
    )

  removeRelation: (relNode) ->
    node = @_getNodeForRelationNode(relNode)
    @_removeRelationNode(relNode)
    relNode.destroy()
    .then(=>
      Weaver.publish("node.relation.remove", {node: @owner, key: @key, target: node})
    )
    
  only: (node) ->
    Promise.map(@nodes, (existing)=>
      @remove(existing) if !existing.equals(node)
    ).then(=>
      @add(node) if @nodes.length is 0
      @owner.save()
    )
    
  onlyOnce: (node) ->
    
    [first, existing...] = @_getRelationNodesForTarget(node)
    if !first?
      @add(node) if @nodes.length is 0
      @owner.save()
    else if existing.length > 0
      Promise.map(existing, (relNode)=>
        @_removeRelationNode(relNode)
        relNode.destroy()
      )
    else
      Promise.resolve()


# Export
module.exports  = WeaverRelation
