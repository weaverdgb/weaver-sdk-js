io      = require('socket.io-client')
Promise = require('bluebird')

module.exports =
class Socket
  
  constructor: (@address) ->
    @io = io.connect(@address, {reconnection: true})

  read: (id, opts) ->
    @emit('read', {id, opts})
    
  create: (type, id, data) ->
    @emit('create', {type, id, data})
    
  emit: (key, body) ->
    deferred = Promise.defer()

    @io.emit(key, body, (response) ->
      if response is 0
        deferred.resolve()
      else
        deferred.resolve(response)
    )

    deferred.promise 
    
  on: (event, callback) ->
    @io.on(event, callback)