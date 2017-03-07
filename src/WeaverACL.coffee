Weaver = require('./Weaver')

# For projects, users and nodes, you can specify which users and roles are allowed to read, and which
# users and roles are allowed to modify.
#
# To support this type of security, each of these objects have an access control list,
# implemented by this WeaverACL class.
class WeaverACL

  constructor: (user) ->
    @_id          = cuid()
    @_objects     = []
    @_publicRead  = false
    @_publicWrite = false

    # Locally these are objects, whereas the server expects arrays
    # Converting to arrays before saving in save function
    @_userReadMap  = {}
    @_userWriteMap = {}
    @_roleReadMap  = {}
    @_roleWriteMap = {}

    @_userWrite[user.id()] = true if user?
    @_deleted = false

  id: ->
    @id

  # Read from server
  @load: (aclId) ->
    coreManager = Weaver.getCoreManager()
    coreManager.readACL(aclId).then((aclObject) ->
      aclObject
    )

  save: ->
    # Convert to array for all values that are true
    trueKeys = (object) ->
      (key for key, value of object when value)

    @_userRead  = trueKeys(@_userReadMap)
    @_userWrite = trueKeys(@_userWriteMap)
    @_roleRead  = trueKeys(@_roleReadMap)
    @_roleWrite = trueKeys(@_roleWriteMap)

    coreManager = Weaver.getCoreManager()
    coreManager.writeACL(@)

  delete: ->
    coreManager = Weaver.getCoreManager()
    coreManager.deleteACL(@).then(=>
      @_deleted = true
      return
    )

  setPublicReadAccess: (allowed) ->
    @publicRead = allowed

  getPublicReadAccess: ->
    @publicRead

  setPublicWriteAccess: (allowed) ->
    @publicWrite = allowed

  getPublicWriteAccess: ->
    @publicWrite

  setUserReadAccess: (user, allowed) ->
    @userReadMap[user.id()] = allowed

  setUserWriteAccess: (user, allowed) ->
    @userWriteMap[user.id()] = allowed

  getUserReadAccess: (user) ->
    @userReadMap[user.id()] or false

  getUserWriteAccess: (user) ->
    @userWriteMap[user.id()] or false

  setRoleReadAccess: (role, allowed) ->
    @roleReadMap[role.id()] = allowed

  setRoleWriteAccess: (role, allowed) ->
    @roleWriteMap[role.id()] = allowed

  getRoleReadAccess: (role) ->
    @roleReadMap[role.id()] or false

  getRoleWriteAccess: (role) ->
    @roleWriteMap[role.id()] or false


module.exports = WeaverACL
