# Libs
io       = require('socket.io-client')
Promise  = require('bluebird')
pjson    = require('../package.json')
Weaver   = require('./Weaver')
ss       = require('socket.io-stream')

class SocketController

  constructor: (@address, @options) ->
    defaultOptions =
      reconnection: true
      rejectUnauthorized: true

    @options = @options or defaultOptions
    @options.reconnection = true
    @options.query = "sdkVersion=#{pjson.version}&requiredServerVersion=#{pjson.com_weaverplatform.requiredServerVersion}&requiredConnectorVersion=#{pjson.com_weaverplatform.requiredConnectorVersion}"

  connect: ->
    new Promise((resolve, reject) =>
      @io = io.connect(@address, @options)

      @io.on('socket.shout', (msg) ->
        Weaver.publish('socket.shout', msg)
      )

      @io.on('connect', =>
        resolve()
      ).on('connect_error', ->
        reject('connect_error')
      ).on('connect_timeout', ->
        reject('connect_timeout')
      ).on('error', (err) ->
        reject(err or 'error')
      )
    )

  emit: (key, body) ->
    new Promise((resolve, reject) =>
      if body.type isnt 'STREAM'
        body = JSON.stringify(body)
        socket = @io
      else
        socket = ss(@io)

      socket.emit(key, body, (response) ->
      emitStart = Date.now()
        if response.code? and response.message?
          error = new Error(response.message)
          error.code = response.code
          reject(error)
        else if response is 0
          resolve()
        else
          resolve(response)
        @_calculateTimestamps(response, emitStart, Date.now())
      )
    )

  _calculateTimestamps: (response, emitStart, emitEnd) ->
    # response.serverEnterTimestamp = response.serverStart
    response.sdkToServer  = response.serverStart - emitStart
    response.innerServerDelay = response.serverStartConnector - response.serverStart
    response.serverToConn = response.executionTimeStart - response.serverStartConnector
    response.connToServer = response.serverEnd - response.processingTimeEnd
    response.serverToSdk  = emitEnd - response.serverEnd
    response.totalTime = emitEnd - emitStart
    response

  GET: (path, body) ->
    @emit(path, body)

  POST: (path, body) ->
    @emit(path, body)

  STREAM: (path, body) ->
    @emit(path, body)

module.exports = SocketController
