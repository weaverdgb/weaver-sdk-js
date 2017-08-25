cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')


class WeaverUser

  constructor: (@username, @password, @email) ->
    @userId   = cuid()

  @get: (authToken) ->
    user = new WeaverUser()
    user.authToken = authToken
    user

  @loadFromServerObject: (user) ->
    u = new Weaver.User()
    u[key] = value for key, value of user
    u

  populateFromServer: (serverUser) ->
    @[key] = value for key, value of serverUser

  id: ->
    @userId

  # Saves the user without signing up
  create: ->
    Weaver.getCoreManager().signUpUser(@).then((authToken) =>
      delete @password
      @authToken = authToken
      return
    )

  save: ->
    Weaver.getCoreManager().updateUser(@)

  changePassword: (password) ->
    Weaver.getCoreManager().changePassword(@userId, password)

  # Saves the user and signs in as current user
  signUp: ->
    @create().then(=>
      Weaver.getCoreManager().currentUser = @
    )

  destroy: ->
    Weaver.getCoreManager().destroyUser(@id())

  getRoles: ->
    Weaver.getCoreManager().getRolesForUser(@userId).then((roles) ->
      (Weaver.Role.loadFromServerObject(r) for r in roles)
    )

  getProjects: ->
    Weaver.getCoreManager().getProjectsForUser(@userId).then((projects) ->
      (new Weaver.Project(p.name, p.id, p.acl, true) for p in projects)
    )

  getPresentInACL: ->
    Weaver.getCoreManager().getACLForObject(@userId).then((acl) ->
      (WeaverACL.loadFromServerObject(a) for a in acl)
    )

  @list: ->
    Weaver.getCoreManager().listUsers().then((users) ->
      (WeaverUser.loadFromServerObject(u) for u in users)
    )
  
  @listProjectUsers: ->
    Weaver.getCoreManager().listProjectUsers(Weaver.getCoreManager().currentProject).then((users) ->
      (WeaverUser.loadFromServerObject(u) for u in users)
    )

# Export
module.exports = WeaverUser
