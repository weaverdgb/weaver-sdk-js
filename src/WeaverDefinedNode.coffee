Weaver      = require('./Weaver')
Promise     = require('bluebird')

class WeaverDefinedNode extends Weaver.Node

  constructor: (nodeId, graph) ->
    super(nodeId, graph)
    @nodeId = nodeId
    @graph = graph

  getDefinitions: ->
    defs = (def.id() for def in @relation(@model.getMemberKey()).all())
    defs = @model.addSupers(defs)
    defs
    
# Export
module.exports = WeaverDefinedNode
