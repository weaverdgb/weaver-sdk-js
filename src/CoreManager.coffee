# Libs
io               = require('socket.io-client')
cuid             = require('cuid')
Promise          = require('bluebird')
SocketController = require('./SocketController')
loki             = require('lokijs')

class CoreManager

  constructor: (@address) ->
    @db = new loki('weaver-sdk')
    @users = @db.addCollection('users')
    @currentProject = null

  connect: ->
    @commController = new SocketController(@address)
    @commController.connect()

  getCommController: ->
    @commController

  executeOperations: (operations, project) ->
    # Fallback to currentProject if project not given
    project = @currentProject if not project?

    # If still undefined, raise an error
    if not project?
      Promise.reject({code: -1, message:"Select a project before saving"})
    else
      @commController.write({operations, project})

  getUsersDB: ->
    @users

  getProjectsDB: ->
    @projects

  logIn: (credentials) ->
    @commController.logIn(credentials)

  signUp: (newUserPayload) ->
    @commController.signUp(newUserPayload)

  signOff: (userPayload) ->
    @commController.signOff(userPayload)

  permission: (userPayload) ->
    @commController.permission(userPayload)

  listProjects: ->
    @commController.GET("project")

  createProject: (id) ->
    @commController.POST("project.create", {id})

  readyProject: (id) ->
    @commController.POST("project.ready", {id})

  deleteProject: (id) ->
    @commController.POST("project.delete", {id})

  getNode: (nodeId)->
    @commController.POST('read', {nodeId})

module.exports = CoreManager
