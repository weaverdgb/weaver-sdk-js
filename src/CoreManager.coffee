# Libs
_                = require('lodash')
io               = require('socket.io-client')
cuid             = require('cuid')
Promise          = require('bluebird')
SocketController = require('./SocketController')
LocalController  = require('./LocalController')
request          = require('request')
Error            = require('./Error')
WeaverError      = require('./WeaverError')

class CoreManager

  constructor: ->
    @currentProject = null
    @timeOffset = 0

  connect: (endpoint) ->
    @endpoint = endpoint
    @commController = new SocketController(endpoint)
    @commController.connect()


  local: (routes) ->
    @commController = new LocalController(routes)
    Promise.resolve()

  getCommController: ->
    @commController

  _resolveTarget: (target) ->
    # Fallback to currentProject if target not given
    target = target or @currentProject.id() if @currentProject?
    target

  _resolvePayload: (payload, target) ->
    payload = payload or {}
    payload.target = @_resolveTarget(target)
    if @currentUser?
      payload.authToken = @currentUser.authToken

    payload

  serverTime: ->
    clientTime = new Date().getTime()
    clientTime - @timeOffset

  updateLocalTimeOffset: ->
    @localTimeOffset().then((offset)=>
      @timeOffset = offset
      offset
    )

  localTimeOffset: ->
    startRequest = new Date().getTime()
    @GET("application.time").then((serverTime)->
      endRequest = new Date().getTime()
      localTime = endRequest - Math.round((endRequest - startRequest) / 2)
      localTime - serverTime
    )


  executeOperations: (operations, target) ->
    @POST('write', {operations}, target)

  serverVersion: ->
    @POST('application.version')

  serverVersion: ->
    @GET("application.version")

  listProjects: ->
    @GET("project")

  createProject: (id, name) ->
    @POST("project.create", {id, name})

  listPlugins: ->
    @GET("plugins").then((plugins) ->
      (new Weaver.Plugin(p) for p in plugins)
    )

  getPlugin: (name) ->
    @POST("plugin.read", {name}).then((plugin) ->
      new Weaver.Plugin(plugin)
    )

  executePluginFunction: (route, payload) ->
    @POST(route, payload)

  createRole: (role) ->
    @POST("role.create", {role})

  getACL: (objectId) ->
    @GET("acl.read.byObject", {objectId}).then((aclObject) ->
      Weaver.ACL.loadFromServerObject(aclObject)
    )

  signInUsername: (username, password) ->
    @POST("user.signInUsername", {username, password}, "$SYSTEM")
      .then((authToken) =>
        @_handleSignIn(authToken)
      )

  # Sign the user in using an authToken
  signInToken: (authToken) ->
    @POST("user.signInToken", {authToken}, "$SYSTEM")
      .then((authToken) =>
        @_handleSignIn(authToken)
      )

  _handleSignIn: (authToken) ->
    @currentUser = Weaver.User.get(authToken)
    @POST("user.read", {}, "$SYSTEM").then((serverUser) =>
      @currentUser.populateFromServer(serverUser)
      @currentUser
    )

  signUpUser: (user) ->
    payload =
      userId: user.userId
      username: user.username
      password: user.password
      email: user.email

    @POST("user.signUp", payload, "$SYSTEM")


  destroyUser: (user) ->
    payload =
      username: user.username

    @POST("user.delete", payload, "$SYSTEM")


  signOutCurrentUser: ->
    @POST("user.signOut", {}, "$SYSTEM").then(=>
      @currentUser = undefined
      return
    )

  readyProject: (id) ->
    @GET("project.ready", {id}, "$SYSTEM")

  deleteProject: (id) ->
    @POST("project.delete", {id}, id)

  getAllNodes: (attributes, target)->
    @POST('nodes', {attributes}, target)

  getAllRelations: (target)->
    @GET('relations', target)

  getHistory: (payload, target)->
    @GET('history', payload, target)

  dumpHistory: (payload, target)->
    @GET('history', payload, target)


  wipe: (target)->
    @POST('wipe', {}, target)

  query: (query) ->
    # Remove target
    target = query.target
    query  = _.omit(query, 'target')

    @POST("query", {query}, target)

  nativeQuery: (query, target) ->
    @POST("query.native", {query}, target)

  wipe: ->
    @POST("application.wipe")

  readACL: (aclId) ->
    @GET("acl.read", {id: aclId}).then((aclObject) ->
      Weaver.ACL.loadFromServerObject(aclObject)
    )

  createACL: (acl) ->
    @POST("acl.create", {acl})

  writeACL: (acl) ->
    @POST("acl.update", {acl})

  deleteACL: (aclId) ->
    @POST("acl.delete", {id: aclId})


  REQUEST: (type, path, payload, target) =>
    payload = @_resolvePayload(payload, target)

    if type is "GET"
      return @commController.GET(path, payload)
    else
      return @commController.POST(path, payload)

  REQUEST_HTTP: (path, payload, target) ->
    payload = @_resolvePayload(payload, target)


  deleteFileByID: (file) ->
    file = @_resolvePayload(file)
    @commController.POST('file.deleteByID',file)

  uploadFile: (formData) ->
    formData = @_resolvePayload(formData)
    new Promise((resolve, reject) =>
      request.post({url:"#{@endpoint}/upload", formData: formData}, (err, httpResponse, body) ->
        if err
          if err.code is 'ENOENT'
            reject(Error WeaverError.FILE_NOT_EXISTS_ERROR,"The file #{err.path} does not exits")
          else
            reject(Error WeaverError.OTHER_CAUSE,"Unknown error")
        else
          resolve(httpResponse.body)
      )
    )

  downloadFileByID: (payload, target) ->
    payload = @_resolvePayload(payload, target)
    payload = JSON.stringify(payload)
    request.get("#{@endpoint}/file/downloadByID?payload=#{payload}")
    .on('response', (res) ->
      res
    )

  GET: (path, payload, target) ->
    @REQUEST("GET", path, payload, target)



  POST: (path, payload, target) ->
    @REQUEST("POST", path, payload, target)


module.exports = CoreManager
