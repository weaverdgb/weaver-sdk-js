cuid        = require('cuid')
Operation   = require('./Operation')
Weaver      = require('./Weaver')
WeaverNode  = require('./WeaverNode')

class WeaverRelationNode extends WeaverNode

  constructor: (nodeId, graphId) ->
    throw new Error("Please always supply a relId when constructing WeaverRelationNode") if not nodeId?

    super(nodeId, graphId)

    @fromNode = null      # is set elsewhere
    @toNode = null        # is set elsewhere

  from: ->
    @fromNode

  to: ->
    @toNode

# Export
module.exports = WeaverRelationNode
