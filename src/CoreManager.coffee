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

  getNode: (nodeId)->
    @commController.POST('read', {nodeId})

module.exports = CoreManager