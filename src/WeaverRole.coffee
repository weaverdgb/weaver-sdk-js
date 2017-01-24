Weaver     = require('./Weaver')

# For any node, you can specify which users and roles are allowed to read the node, and which users and roles are
# allowed to modify an node. To support this type of security, each node has an access control list,
# implemented by the WeaverACL class.
class WeaverRole extends Weaver.SystemNode

  constructor: (@nodeId) ->
    super(@nodeId)

  @get: (nodeId) ->
    super(nodeId, WeaverRole)

  # Relations
  getUsers: ->

  getRoles: ->



module.exports = WeaverRole
