Operation = require('./Operation')
WeaverRoot  = require('./WeaverRoot')

class WeaverRelation extends WeaverRoot

  getClass: ->
    WeaverRelation
  @getClass: ->
    WeaverRelation

  constructor: (@parent, @key) ->
    @pendingWrites = []   # All operations that need to get saved
    @nodes = {}           # All nodes that this relation points to
    @relationNodes = {}   # Map node id to RelationNode

  load: ->
    Promise.resolve([])

  query: ->
    Promise.resolve([])


  to: (node)->
    throw new Error("No relation to a node with this id: #{node.id()}") if not @relationNodes[node.id()]
    Weaver = @getWeaverClass()
    console.log("about to load #{@relationNodes[node.id()].id()}")
    Weaver.RelationNode.load(@relationNodes[node.id()].id(), null, Weaver.RelationNode)

  all: ->
    (node for key, node of @nodes)

  add: (node, relId) ->
    relId = cuid() if not relId?
    @nodes[node.id()] = node
    Weaver = @getWeaverClass()
    @relationNodes[node.id()] = Weaver.RelationNode.get(relId, Weaver.RelationNode)
    @pendingWrites.push(Operation.Node(@parent).createRelation(@key, node.id(), relId))

  update: (oldNode, newNode) ->
    relId = @relationNodes[oldNode.id()].id()
    delete @nodes[oldNode.id()]
    @nodes[newNode.id()] = newNode
    @pendingWrites.push(Operation.Node(@parent).updateRelation(@key, oldNode.id(), newNode.id(), relId))


  remove: (node) ->
    delete @nodes[node.id()]
    delete @relationNodes[node.id()]
    @pendingWrites.push(Operation.Node(@parent).removeRelation(@key, node.id()))


# Export
module.exports  = WeaverRelation
