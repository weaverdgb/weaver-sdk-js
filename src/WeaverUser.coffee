# Libs
cuid   = require('cuid')
Weaver = require('./Weaver')
loki   = require('lokijs')

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
    users = Weaver.getUsersDB()
    coreManager.logIn(credentials)
    .then((res) ->
      try
        users.insert({user:usr,token:res.token})
      catch error
        console.error(error)
      res
    )
    
  # Returns the "valid" token from current user, null if not loggedin
  current: (usr) ->
    new Promise((resolve, reject) =>
      try
        users = Weaver.getUsersDB()
        resolve(users.findOne({user:usr}).token)
      catch error
        reject(null)
    )
    
    
# Export
Weaver.User    = WeaverUser
module.exports = WeaverUser

#  TODO: Stuff to do!
#     @signUp: ->
#
#     @logOut: ->






