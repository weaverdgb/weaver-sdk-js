cuid = require('cuid')
Weaver  = require('./Weaver')

class WeaverRelationIn
  constructor: (@key) ->
    @nodes = []           # All nodes that this relation points to

  all: ->
    @nodes

  first: ->
    @.all()[0]

  addSource: (node) ->
    @nodes.push(node)

# Export
module.exports  = WeaverRelationIn
