# Libs
cuid = require('cuid')
WeaverNode = require('./WeaverNode')


module.exports =
  class WeaverUser extends WeaverNode

    constructor: () ->
      @email
      @username
      @password
      @emailVerified = false

    signUp: ->

    # Returns current loggedin user (or null if not loggedin)
    @current: ->

    @logOut: ->


    @logIn: (username, password) ->




