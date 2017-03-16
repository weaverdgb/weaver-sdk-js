Weaver      = require('./Weaver')
CoreManager = Weaver.getCoreManager()
cuid        = require('cuid')

# For any node, you can specify which users and roles are allowed to read the node, and which users and roles are
# allowed to modify an node. To support this type of security, each node has an access control list,
# implemented by the WeaverACL class.
class WeaverRole

  constructor: (@name) ->
    @name = @name or "unnamed"
    @roleId = cuid()

    # State
    @_created = false
    @_deleted = false

    # Locally these are objects, whereas the server expects arrays
    # Converting to arrays before saving in save function
    @_usersMap = {}
    @_rolesMap = {}

  save: ->
    @_users = @getUsers()
    @_roles = @getRoles()

    if not @_created
      CoreManager.createRole(@).then(=>
        @_created = true
        @
      )
    else
      CoreManager.updateRole(@)

  id: ->
    @roleId

  addUser: (user) ->
    @_usersMap[user.id()] = null

  removeUser: (user) ->
    delete @_usersMap[user.id()]

  addRole: (role) ->
    @_rolesMap[role.id()] = null

  removeRole: (role) ->
    delete @_rolesMap[role.id()]

  getUsers: ->
    (userId for userId, val of @_usersMap)

  getRoles: ->
    (roleId for roleId, val of @_rolesMap)

  delete: ->
    CoreManager.deleteRole(@id()).then(=>
      @_deleted = true
    )

module.exports = WeaverRole
