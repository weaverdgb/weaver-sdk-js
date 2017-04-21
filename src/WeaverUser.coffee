cuid        = require('cuid')
Promise     = require('bluebird')
WeaverRoot  = require('./WeaverRoot')


class WeaverUser extends WeaverRoot

  getClass: ->
    WeaverUser
  @getClass: ->
    WeaverUser

  constructor: (@username, @password, @email) ->
    @userId   = cuid()
    @_stored = false

  @get: (authToken) ->
    user = new WeaverUser()
    user.userId    = undefined
    user._stored  = true
    user.authToken = authToken
    user

  populateFromServer: (serverUser) ->
    @[key] = value for key, value of serverUser

  id: ->
    @userId

  # Saves the user without signing up
  create: ->
    @getWeaver().getCoreManager().signUpUser(@).then((user) =>
      delete @password
      user
    )

  # Saves the user and signs in as current user
  signUp: ->
    @create().then((authToken) =>
      @authToken = authToken
      @_stored = true
      @getWeaver().getCoreManager().currentUser = @
    )

  destroy: ->
    @getWeaver().getCoreManager().destroyUser(@)

  @list: ->
    Promise.resolve([]) # TODO: Implement

# Export
module.exports = WeaverUser
