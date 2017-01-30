Promise = require('bluebird')

class LocalEventController

  constructor: (@bus) ->

  _emit: (key, payload) ->
    @bus.emit(key, {payload})

  GET: (path) ->
    @_emit(path)

  POST: (path, body) ->
    @_emit(path, body)

module.exports = LocalEventController
