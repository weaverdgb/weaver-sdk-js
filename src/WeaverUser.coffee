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
      user: usr
      password: pass
    }
    coreManager = Weaver.getCoreManager()
    users = Weaver.getUsersDB()
    coreManager.logIn(credentials)
    .then((res) ->
      try
        #
        users.insert({user:usr,token:res.token})
      catch error
        console.error(error)
      res
    )
  
  signUp: (currentUsr,userName,userEmail,userPassword,directoryName) ->
    newUserCredentials = {
      userName: userName
      userEmail: userEmail
      userPassword: userPassword
      directoryName: directoryName
    }
    coreManager = Weaver.getCoreManager()
    @current(currentUsr).then((token) ->
      newUserPayload = {
        newUserCredentials: newUserCredentials
        access_token: token
      }
      coreManager.signUp(newUserPayload)
    )
    
  
  signOff: (currentUsr, user) ->
    coreManager = Weaver.getCoreManager()
    @current(currentUsr).then((token) ->
      userPayload = {
        user: user
        access_token: token
      }
      coreManager.signOff(userPayload)
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
  
  ###
  # log out action, will remove the jwt at the current user
  # passing a user is optional
  ###
  
  logOut: (usr) ->
    new Promise((resolve, reject) =>
      try
        users = Weaver.getUsersDB()
        if usr?
          users.remove(users.find({$and:[{user:usr},{token:{$ne:undefined}}]}))
          resolve()
        else
          users.remove(users.find({token:{$ne:undefined}}))
          resolve()
      catch error
        reject(error)
          
    )
    
    
# Export
Weaver.User    = WeaverUser
module.exports = WeaverUser






