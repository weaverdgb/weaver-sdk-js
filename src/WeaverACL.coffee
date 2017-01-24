Weaver = require('./Weaver')

# For any node, you can specify which users and roles are allowed to read the node, and which users and roles are
# allowed to modify an node. To support this type of security, each node has an access control list,
# implemented by the WeaverACL class.
class WeaverACL extends Weaver.SystemNode

  constructor: (@nodeId) ->
    super(@nodeId)

  @get: (nodeId) ->
    super(nodeId, WeaverACL)


  ## PUBLIC ##

  setPublicReadAccess: (allowed) ->

  getPublicReadAccess: ->
    true

  setPublicWriteAccess: (allowed) ->

  getPublicWriteAccess: ->
    true



  ## USER ##

  setUserReadAccess: (user, allowed) ->

  setUserWriteAccess: (user, allowed) ->

  getUserReadAccess: (user) ->
    true

  getUserWriteAccess: (user) ->
    true



  ## ROLE ##

  setRoleReadAccess: (role, allowed) ->

  setRoleWriteAccess: (role, allowed) ->

  getRoleReadAccess: (role) ->
    true

  getRoleWriteAccess: (role) ->
    true


module.exports = WeaverACL
