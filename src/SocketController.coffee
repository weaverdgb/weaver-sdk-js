# Libs
io             = require('socket.io-client')
cuid           = require('cuid')
Promise        = require('bluebird')

class SocketController

  constructor: (@address) ->

  connect: ->
    @io = io.connect(@address, {reconnection: true})
    Promise.resolve()

  emit: (key, body) ->
    new Promise((resolve, reject) =>
      @io.emit(key, JSON.stringify(body), (response) ->
        if response.code? and response.message?
          reject(response)
        else if response is 0
          resolve()
        else
          resolve(response)
      )
    )

  GET: (path) ->
    @emit(path)

  POST: (path, body) ->
    @emit(path, body)

  write: (operations) ->
    @emit("write", operations)
    
  logIn: (credentials) ->
    @emit("logIn",credentials)
    
  signUp: (newUserPayload) ->
    @emit("signUp",newUserPayload)
  
  signOff: (userPayload) ->
    @emit("signOff",userPayload)

  listProjects: ->
    @emit("project")

  createProject: (project) ->
    @POST("project.create", {name: project.name})

  deleteProject: (project) ->
    @POST("project.delete", {id: project.id})

module.exports = SocketController
