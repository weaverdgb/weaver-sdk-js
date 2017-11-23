# Libs
_                = require('lodash')
io               = require('socket.io-client')
cuid             = require('cuid')
Promise          = require('bluebird')
request          = require('request')
SocketController = require('./SocketController')
LocalController  = require('./LocalController')
Error            = require('./Error')
Weaver           = require('./Weaver')
WeaverError      = require('./WeaverError')

class CoreManager

  constructor: ->
    @currentProject = null
    @currentModel   = null
    @operationsQueue = Promise.resolve()
    @timeOffset = 0
    @maxBatchSize = 500

  connect: (endpoint, @options) ->
    defaultOptions =
      rejectUnauthorized: true

    @options = @options or defaultOptions
    @endpoint = endpoint
    @commController = new SocketController(endpoint, @options)
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

  _resolvePayload: (type, payload, target) ->
    payload = payload or {}
    payload.type = type

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

  executeOperations: (allOperations, target) ->
    Promise.mapSeries(_.chunk(allOperations, @maxBatchSize), (operations) =>
      @POST('write', {operations}, target)
    )

#  serverVersion: ->
#    @POST('application.version')

  cloneNode: (sourceId, targetId = cuid(), relationsToTraverse) ->
    @POST('node.clone', { sourceId, targetId, relationsToTraverse})

  serverVersion: ->
    @GET("application.version")

  listProjects: ->
    @GET("project")

  listUsers: ->
    @GET("users")

  listProjectUsers: (project) ->
    @GET("projectUsers", { id: project.id })

  listRoles: ->
    @GET("roles")

  listACL: ->
    @GET("acl.all")

  createProject: (id, name) ->
    @POST("project.create", {id, name})

  shout: (message) ->
    @POST("socket.shout", {message})

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

  getModel: (name, version) ->
    @POST("model.read", {name, version}).then((model) ->
      new Weaver.Model(model)
    )

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
    update = {}
    update[key] = value for key, value of user

    @POST("user.signUp", update, "$SYSTEM")


  updateUser: (user) ->
    update      = {}
    update[key] = value for key, value of user when key isnt 'authToken'

    @POST("user.update", {update})

  updateRole: (role) ->
    update      = {}
    update[key] = value for key, value of role

    @POST("role.update", {update})

  changePassword: (userId, password) ->
    @POST("user.changePassword", {userId, password})

  destroyUser: (id) ->
    @POST("user.delete", {id}, "$SYSTEM")

  destroyRole: (id) ->
    @POST("role.delete", {id}, "$SYSTEM")

  signOutCurrentUser: ->
    @POST("user.signOut", {}, "$SYSTEM").then(=>
      @currentUser = undefined
      return
    )

  executeZippedWriteOperations: (id, filename) ->
    @POST("project.executeZip", {id, filename}, id)

  readyProject: (id) ->
    @GET("project.ready", {id}, "$SYSTEM")

  nameProject: (id, name) ->
    @POST("project.name", {id, name}, id)

  freezeProject: (id) ->
    @GET("project.freeze", {id}, id)

  unfreezeProject: (id) ->
    @GET("project.unfreeze", {id}, id)

  addApp: (id, app) ->
    @GET("project.app.add", {id, app}, id)

  removeApp: (id, app) ->
    @GET("project.app.remove", {id, app}, id)

  cloneProject: (id, clone_id, name) ->
    @POST("project.clone", {id: clone_id, name}, id)

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

  snapshotProject: (target, zipped)->
    @GET('snapshot', {zipped}, target)

  wipeProject: (target)->
    @POST('project.wipe', {}, target)

  wipeProjects: (target)->
    @POST('projects.wipe', {}, target)

  destroyProjects: (target)->
    @POST('projects.destroy', {}, target)

  wipeUsers: (target)->
    @POST('users.wipe', {}, target)

  query: (query) ->
    # Remove target
    target = query.target
    query  = _.omit(query, ['target', 'useConstructorFunction'])

    @POST("query", {query}, target)

  nativeQuery: (query, target) ->
    @POST("query.native", {query}, target)

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

  getRolesForUser: (userId) ->
    @POST("user.roles", {id: userId})

  getProjectsForUser: (userId) ->
    @POST("user.projects", {id: userId})

  REQUEST: (type, path, payload, target) =>
    payload = @_resolvePayload(type, payload, target)

    switch(type)
      when "GET" then @commController.GET(path, payload)
      when "POST" then @commController.POST(path, payload)
      when "STREAM" then @commController.STREAM(path, payload)

  REQUEST_HTTP: (path, payload, target) ->
    payload = @_resolvePayload(payload, target)

  listFiles: ->
    @GET("file.list")

  downloadFile: (fileId) ->
    @STREAM("file.download", {fileId})

  uploadFile: (stream, filename) ->
    @STREAM("file.upload", {file: stream, filename})

  deleteFile: (fileId) ->
    @POST("file.delete", {fileId})

  enqueue: (functionToEnqueue) ->
    op = @operationsQueue.then(->
      functionToEnqueue()
    )

    new Promise((resultResolve, resultReject) =>
      @operationsQueue = new Promise((resolve) =>
        op.then((r)->
          resolve()
          resultResolve(r)
        ).catch((e) ->
          resolve()
          resultReject(e)
        )
      )
    )


  GET: (path, payload, target) ->
    @REQUEST("GET", path, payload, target)

  POST: (path, payload, target) ->
    @REQUEST("POST", path, payload, target)

  STREAM: (path, payload, target) ->
    @REQUEST("STREAM", path, payload, target)


module.exports = CoreManager
