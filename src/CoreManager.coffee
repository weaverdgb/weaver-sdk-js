# Libs
io             = require('socket.io-client')
cuid           = require('cuid')
Promise        = require('bluebird')
SocketController = require('./SocketController')

class CoreManager

  constructor: (@address) ->

  connect: ->
    # TODO: Add support for HTTPController if Sockets are not available
    @commController = new SocketController(@address)
    @commController.connect()

  getCommController: ->
    @commController

  executeOperations: (operations) ->
    Promise.resolve()

module.exports = CoreManager
