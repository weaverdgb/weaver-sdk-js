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

  connect: ->
    @commController = new SocketController(@address)
    @commController.connect()

  getCommController: ->
    @commController

  executeOperations: (operations) ->
    @commController.write(operations)
    
  getUsersDB: ->
    @users
    
  logIn: (credentials) ->
    @commController.logIn(credentials)
    
  signUp: (newUserPayload) ->
    @commController.signUp(newUserPayload)
    
  signOff: (userPayload) ->
    @commController.signOff(userPayload)

module.exports = CoreManager
