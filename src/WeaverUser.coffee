cuid        = require('cuid')
Weaver      = require('./Weaver')
loki        = require('lokijs')
Error       = Weaver.LegacyError
WeaverError = Weaver.Error

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
    coreManager = Weaver.getCoreManager()
    coreManager.signUpUser(@).then((user) =>
      delete @password
      user
    )

  # Saves the user and signs in as current user
  signUp: ->
    coreManager = Weaver.getCoreManager()
    @create().then((authToken) =>
      @authToken = authToken
      @_created = true
      coreManager.currentUser = @
    )


  destroy: ->
    coreManager = Weaver.getCoreManager()
    coreManager.destroyUser(@)

  save: ->
    if not @_created
      Promise.reject({error: -1, message: 'Should call signUp() first before saving'})
    else
      super()

  @load: (nodeId) ->
    super(nodeId, WeaverUser)

  @list: ->
    new Weaver.Query("$SYSTEM").equalTo("type", "user").find()


  @logIn: (user, password) ->
    credentials = {user,password}
    coreManager = Weaver.getCoreManager()
    users = Weaver.getUsersDB()
    coreManager.logIn(credentials)
    .then((res) ->
      try
        users.insert({user:user,token:res.token})
      catch error
      res
    )

  permission: (user) ->
    coreManager = Weaver.getCoreManager()
    weaverUser = new WeaverUser()
    weaverUser.current(user).then((accessToken) ->
      userPayload = {user,accessToken}
      coreManager.permission(userPayload)
    )

  @signUp: (currentUsr,userName,userEmail,userPassword,directoryName) ->
    newUserCredentials = {userName,userEmail,userPassword,directoryName}
    coreManager = Weaver.getCoreManager()
    weaverUser = new WeaverUser()
    weaverUser.current(currentUsr).then((accessToken) ->
      newUserPayload = {newUserCredentials,accessToken}
      coreManager.signUp(newUserPayload)
    )


  @signOff: (currentUsr, user) ->
    coreManager = Weaver.getCoreManager()
    weaverUser = new WeaverUser()
    weaverUser.current(currentUsr).then((accessToken) ->
      userPayload = {user,accessToken}
      coreManager.signOff(userPayload)
    )

  @list: (currentUsr, directory) ->
    coreManager = Weaver.getCoreManager()
    weaverUser = new WeaverUser()
    weaverUser.current(currentUsr).then((accessToken) ->
      usersList = {directory,accessToken}
      coreManager.usersList(usersList)
    )

  # Returns the "valid" token from current user, null if not loggedin
  current: (usr) ->
    new Promise((resolve, reject) =>
      try
        users = Weaver.getUsersDB()
        resolve(users.findOne({user:usr}).token)
      catch error
        reject(Error WeaverError.SESSION_MISSING,"There is not jwt for the user")
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
          userFound = users.find({$and:[{user:usr},{token:{$ne:undefined}}]})
          if userFound.length is 0
            reject(Error WeaverError.USERNAME_NOT_FOUND,'Username not found')
          else
            users.remove(userFound)
            resolve()
        else
          userFound = users.find({token:{$ne:undefined}})
          if userFound.length is 0
            reject(Error WeaverError.USERNAME_NOT_FOUND,'Username not found')
          else
            users.remove(userFound)
            resolve()
      catch error
        reject(error)

    )


# Export
module.exports = WeaverUser
