# Libs
_                = require('lodash')
io               = require('socket.io-client')
cuid             = require('cuid')
Promise          = require('bluebird')
SocketController = require('./SocketController')
LocalController  = require('./LocalController')
loki             = require('lokijs')

class CoreManager

  constructor: ->
    @db = new loki('weaver-sdk')
    @users = @db.addCollection('users')
    @currentProject = null

  connect: (endpoint) ->
    @commController = new SocketController(endpoint)
    @commController.connect()

  local: (routes) ->
    @commController = new LocalController(routes)
    Promise.resolve()

  getCommController: ->
    @commController

  _resolveTarget: (target) ->
    # Fallback to currentProject if target not given
    if not target? and not @currentProject?
      return Promise.reject({code: -1, message:"Provide a target or select a project before saving"})

    target = @currentProject.id() if not target?
    Promise.resolve(target)

  executeOperations: (operations, target) ->
    @POST('write', {operations}, target)

  getUsersDB: ->
    @users

  getProjectsDB: ->
    @projects

  logIn: (credentials) ->
    @POST('logIn',credentials)

  signUp: (newUserPayload) ->
    @POST('signUp',newUserPayload)

  signOff: (userPayload) ->
    @POST('signOff',userPayload)

  permission: (userPayload) ->
    @POST('permission',userPayload)

  createApplication: (newApplication) ->
    @POST('application',newApplication)

  serverVersion: ->
    @GET("application.version")

  listProjects: ->
    @GET("project")

  createProject: (id) ->
    @POST("project.create", {id}, "$SYSTEM")

  signUpUser: (user) ->
    payload =
      userId: user.userId
      username: user.username
      password: user.password
      email: user.email

    @POST("auth.signUp", payload, "$SYSTEM")

  createUser: (id) ->
    @POST("users.create", {id})

  readyProject: (id) ->
    @POST("project.ready", {id}, "$SYSTEM")

  deleteProject: (id) ->
    @POST("project.delete", {id}, "$SYSTEM")

  getNode: (nodeId, target)->
    @POST('read', {nodeId}, target)

  wipe: (target)->
    @POST('wipe', {}, target)

  usersList: (usersList) ->
    @POST('usersList', usersList)

  query: (query) ->
    # Remove target
    target = query.target
    query  = _.omit(query, 'target')

    @POST("query", {query}, target)


  REQUEST: (type, path, payload, target) ->
    @_resolveTarget(target).then((target) =>
      payload.target = target
      if @currentUser?
        payload.authToken = @currentUser._authToken

      if type is "GET"
        @commController.GET(path, payload)
      else
        @commController.POST(path, payload)

    )

  GET: (path, payload, target) ->
    @REQUEST("GET", path, payload, target)

  POST: (path, payload, target) ->
    @REQUEST("POST", path, payload, target)


module.exports = CoreManager
