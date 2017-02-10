Weaver = require('./Weaver')

class SystemNode extends Weaver.Node

  @TARGET: "$SYSTEM"

  @load: (nodeId, Constructor) ->
    Weaver.Node.load(nodeId, SystemNode.TARGET, Constructor)

  save: ->
    super(SystemNode.TARGET)

  destroy: ->
    super(SystemNode.TARGET)

# Export
module.exports = SystemNode
