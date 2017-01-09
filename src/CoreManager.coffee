# Libs
io             = require('socket.io-client')
cuid           = require('cuid')
Promise        = require('bluebird')
SocketController = require('./SocketController')

class CoreManager

  constructor: (@address) ->

  connect: ->
    @commController = new SocketController(@address)
    @commController.connect()

  getCommController: ->
    @commController

  executeOperations: (operations) ->
    @commController.write(operations)

  createProject: (project) ->
    @commController.createProject(project).then((res) ->
      console.log(res)
      project
    )

  listProjects: ->
    @commController.listProjects()

  deleteProject: (project) ->
    @commController.deleteProject(project)

module.exports = CoreManager
