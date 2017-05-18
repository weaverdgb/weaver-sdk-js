cuid        = require('cuid')
Weaver      = require('./Weaver')

# For any node, you can specify which users and roles are allowed to read the node, and which users and roles are
# allowed to modify an node. To support this type of security, each node has an access control list,
# implemented by the WeaverACL class.
class WeaverRole

  constructor: (@name) ->
    @name = @name or "unnamed"
    @roleId = cuid()

    # State
    @_stored = false
    @_deleted = false

    # Locally these are objects, whereas the server expects arrays
    # Converting to arrays before saving in save function
    @_usersMap = {}
    @_rolesMap = {}

  @loadFromServerObject: (roleObject) ->
    role = new WeaverRole()
    # Copy
    role.roleId    = roleObject.roleId
    role.name      = roleObject.name
    role._stored   = true

    role._usersMap[u] = true for u in roleObject.users
    role._rolesMap[u] = true for u in roleObject.roles

    role

  save: ->
    @_users = @getUsers()
    @_roles = @getRoles()

    if not @_stored
      Weaver.getCoreManager().createRole(@).then(=>
        @_stored = true
        @
      )
    else
      Weaver.getCoreManager().updateRole(@)

  id: ->
    @roleId

  addUser: (user) ->
    @_usersMap[user.id()] = true

  removeUser: (user) ->
    delete @_usersMap[user.id()]

  addRole: (role) ->
    @_rolesMap[role.id()] = true

  removeRole: (role) ->
    delete @_rolesMap[role.id()]

  getUsers: ->
    (userId for userId, val of @_usersMap)

  getRoles: ->
    (roleId for roleId, val of @_rolesMap)

  delete: ->
    Weaver.getCoreManager().deleteRole(@id()).then(=>
      @_deleted = true
    )

module.exports = WeaverRole
