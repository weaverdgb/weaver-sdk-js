cuid        = require('cuid')
Operation   = require('./Operation')
Weaver      = require('./Weaver')
WeaverNode  = require('./WeaverNode')

class WeaverRelationNode extends WeaverNode

  constructor: (@nodeId, @graphId) ->
    throw new Error("Please always supply a relId when constructing WeaverRelationNode") if not @nodeId?

    @toNode = null        # Wip, this is fairly impossible to query this from the server currently
    @fromNode = null      # Wip, this is fairly impossible to query this from the server currently

  to: ->
    @toNode

  from: ->
    @fromNode

# Export
module.exports = WeaverRelationNode
