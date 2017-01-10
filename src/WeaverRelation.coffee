Operation = require('./Operation')

module.exports =
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

      #console.log(node)

    remove: (node) ->
      delete @nodes[node.id()]
      @pendingWrites.push(Operation.Node(@parent).removeRelation(@key, node.id()))