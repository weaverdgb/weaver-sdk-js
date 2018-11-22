# Libs
SocketController = require('./SocketController')
ss = require('socket.io-stream')

class SocketControllerWithStream extends SocketController

  parseBody: (body) ->
    if body.type isnt 'STREAM'
      JSON.stringify(body)
    else
      body

  getSocket: (body) ->
    if body.type isnt 'STREAM'
      @io
    else
      ss(@io)

  STREAM: (path, body) ->
    @emit(path, body)

module.exports = SocketControllerWithStream
