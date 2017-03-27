Weaver    = require('./Weaver')
Operation = require('./Operation')

class WeaverRelation

  constructor: (@parent, @key) ->
    @pendingWrites = []   # All operations that need to get saved
    @nodes = {}           # All nodes that this relation points to

  load: ->
    Promise.resolve([])

  query: ->
    Promise.resolve([])

  add: (node) ->
    @nodes[node.id()] = node
    @pendingWrites.push(Operation.Node(@parent).createRelation(@key, node.id()))

  update: (oldNode, newNode) ->
    delete @nodes[oldNode.id()]
    @nodes[newNode.id()] = newNode
    @pendingWrites.push(Operation.Node(@parent).updateRelation(@key, oldNode.id(), newNode.id()))

  remove: (node) ->
    delete @nodes[node.id()]
    @pendingWrites.push(Operation.Node(@parent).removeRelation(@key, node.id()))


# Export
module.exports  = WeaverRelation
