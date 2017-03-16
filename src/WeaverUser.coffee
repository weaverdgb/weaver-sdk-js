cuid        = require('cuid')
Weaver      = require('./Weaver')
CoreManager = Weaver.getCoreManager()
Promise     = require('bluebird')

class WeaverUser

  constructor: (@username, @password, @email) ->
    @userId   = cuid()
    @_created = false

  @get: (authToken) ->
    user = new Weaver.User()
    user.userId    = undefined
    user._created  = true
    user.authToken = authToken
    user

  populateFromServer: (serverUser) ->
    @[key] = value for key, value of serverUser

  id: ->
    @userId

  # Saves the user without signing up
  create: ->
    CoreManager.signUpUser(@).then((user) =>
      delete @password
      user
    )

  # Saves the user and signs in as current user
  signUp: ->
    @create().then((authToken) =>
      @authToken = authToken
      @_created = true
      CoreManager.currentUser = @
    )

  destroy: ->
    CoreManager.destroyUser(@)

  @list: ->
    Promise.resolve([]) # TODO: Implement

# Export
module.exports = WeaverUser
