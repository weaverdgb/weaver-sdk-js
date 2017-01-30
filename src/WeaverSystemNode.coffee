Weaver = require('./Weaver')

class SystemNode extends Weaver.Node

  @TARGET: "$SYSTEM"

  @load: (nodeId) ->
    Weaver.Node.load(nodeId, SystemNode.TARGET)

  save: ->
    super(SystemNode.TARGET)

  destroy: ->
    super(SystemNode.TARGET)

# Export
module.exports = SystemNode
