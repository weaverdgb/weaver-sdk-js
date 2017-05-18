cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')


class WeaverUser

  constructor: (@username, @password, @email) ->
    @userId   = cuid()
    @_stored = false

  @get: (authToken) ->
    user = new WeaverUser()
    user.userId   = undefined
    user._stored  = true
    user.authToken = authToken
    user

  @loadFromServerObject: (user) ->
    u = new Weaver.User()
    u._stored = true
    u.username = user.username
    u.email    = user.email
    u.userId   = user.userId
    u

  populateFromServer: (serverUser) ->
    @[key] = value for key, value of serverUser

  id: ->
    @userId

  # Saves the user without signing up
  create: ->
    Weaver.getCoreManager().signUpUser(@).then((authToken) =>
      delete @password
      @_stored   = true
      @authToken = authToken
      return
    )

  save: ->
    Weaver.getCoreManager().updateUser(@)

  # Saves the user and signs in as current user
  signUp: ->
    @create().then(=>
      Weaver.getCoreManager().currentUser = @
    )

  destroy: ->
    Weaver.getCoreManager().destroyUser(@)

  @list: ->
    Weaver.getCoreManager().listUsers().then((users) ->
      (WeaverUser.loadFromServerObject(u) for u in users)
    )

# Export
module.exports = WeaverUser
