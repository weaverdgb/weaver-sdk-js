# Libs
io       = require('socket.io-client')
Promise  = require('bluebird')

class SocketController

  constructor: (@address) ->

  connect: ->
    new Promise((resolve, reject) =>
      @io = io.connect(@address, {reconnection: true})
      @io.on('connect', ->
        resolve()
      ).on('connect_error', ->
        reject('connect_error')
      ).on('connect_timeout', ->
        reject('connect_timeout')
      ).on('error', ->
        reject('error'))
    )

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

  GET: (path, body) ->
    @emit(path, body)

  POST: (path, body) ->
    @emit(path, body)

module.exports = SocketController
