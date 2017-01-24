Weaver = require('./Weaver')

class WeaverFile extends Weaver.SystemNode

  constructor: (@nodeId) ->
    super(@nodeId)

  @get: (nodeId) ->
    super(nodeId, WeaverFile)


module.exports = WeaverFile
