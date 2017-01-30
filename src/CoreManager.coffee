# Libs
_                = require('lodash')
io               = require('socket.io-client')
cuid             = require('cuid')
Promise          = require('bluebird')
SocketController = require('./SocketController')
LocalController  = require('./LocalEventController')
loki             = require('lokijs')

class CoreManager

  constructor: ->
    @db = new loki('weaver-sdk')
    @users = @db.addCollection('users')
    @currentProject = null

  connect: (endpoint) ->
    @commController = new SocketController(endpoint)
    @commController.connect()

  local: (bus) ->
    @commController = new LocalController(bus)
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
    @_resolveTarget(target).then((target) =>
      @commController.POST('write', {operations, target})
    )

  getUsersDB: ->
    @users

  getProjectsDB: ->
    @projects

  logIn: (credentials) ->
    @commController.POST('logIn',credentials)

  signUp: (newUserPayload) ->
    @commController.POST('signUp',newUserPayload)

  signOff: (userPayload) ->
    @commController.POST('signOff',userPayload)

  permission: (userPayload) ->
    @commController.POST('permission',userPayload)

  createApplication: (newApplication) ->
    @commController.POST('application',newApplication)

  listProjects: ->
    @commController.GET("project")

  createProject: (id) ->
    @commController.POST("project.create", {id})

  readyProject: (id) ->
    @commController.POST("project.ready", {id})

  deleteProject: (id) ->
    @commController.POST("project.delete", {id})

  getNode: (nodeId, target)->
    @_resolveTarget(target).then((target) =>
      @commController.POST('read', {nodeId, target})
    )

  wipe: (target)->
    @commController.POST('wipe', {target})

  usersList: (usersList) ->
    @commController.POST('usersList', usersList)

  query: (query) ->
    # Remove target
    target = query.target
    query  = _.omit(query, 'target')

    @_resolveTarget(target).then((target) =>
      @commController.POST("query", {query, target})
    )
    
  sendFile: (file) ->
    @commController.POST('uploadFile', file)
    
  getFile: (file) ->
    @commController.POST('downloadFile',file)
    
  getFileByID: (file) ->
    @commController.POST('downloadFileByID',file)
    
  deleteFile: (file) ->
    @commController.POST('deleteFile',file)
    
  deleteFileByID: (file) ->
    @commController.POST('deleteFileByID',file)

module.exports = CoreManager
