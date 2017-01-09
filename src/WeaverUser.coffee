# Libs
cuid = require('cuid')
Weaver    = require('./Weaver')

class WeaverUser
  
  constructor: () ->
    @email
    @username
    @password
    @emailVerified = false
    
    
  logIn: (usr, pass) ->
    credentials = {
      user:usr
      password:pass
    }
    coreManager = Weaver.getCoreManager()
    coreManager.logIn(credentials)
    .then((res) ->
      res
    )
    
    
# Export
Weaver.User    = WeaverUser
module.exports = WeaverUser

#  TODO: Stuff to do!
#     @signUp: ->
#
#     # Returns current loggedin user (or null if not loggedin)
#     @current: ->
#
#     @logOut: ->






