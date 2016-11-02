# Libs
io      = require('socket.io-client')
Promise = require('bluebird')

# Transport layer to server using socket.io
module.exports =
class Socket

  constructor: (@address) ->
    @io = io.connect(@address, {reconnection: true})

  read: (payload) ->
    # console.log '=^^=|_READ'
    @emit('read', payload)

  create: (payload) ->
    @emit('create', payload)

  endBulk: ->
    @emit('bulkEnd')

  startBulk: ->
    @emit('bulkStart')

  authenticate: (payload) ->
    @emit('authenticate', payload)

  update: (payload) ->
    @emit('update', payload)

  link: (payload) ->
    @emit('link', payload)

  unlink: (payload) ->
    @emit('unlink', payload)

  destroy: (payload) ->
    @emit('destroy', payload)

  remove: (payload) ->
    @emit('remove', payload)

  wipe: () ->
    @emit('wipe', {})

  bootstrapFromUrl: (url) ->
    @emit('bootstrapFromUrl', url)

  bootstrapFromJson: (json) ->
    @emit('bootstrapFromJson', json)

  onUpdate: (id, callback) ->
    @on(id + ':updated', callback)

  onLinked: (id, callback) ->
    @on(id + ':linked', callback)

  onUnlinked: (id, callback) ->
    @on(id + ':unlinked', callback)

  # TODO: Handle errors from server
  emit: (key, body) ->
    new Promise((resolve, reject) =>
      @io.emit(key, body, (response) ->
        if response is 0
          resolve()
        else
          resolve(response)
      )
    )

  on: (event, callback) ->
    @io.on(event, callback)

  disconnect: ->
    @io.disconnect()

  queryFromView: (payload) ->
    @emit('queryFromView', payload)

  queryFromFilters: (payload) ->
    @emit('queryFromFilters', payload)

  nativeQuery: (payload) ->
    @emit('nativeQuery', payload)
