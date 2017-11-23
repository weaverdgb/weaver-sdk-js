cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')

class WeaverApp

  constructor: (@id, @version, @name) ->

  # Load all apps from server
  @list: ->
    Weaver.getCoreManager().listApps().then((list) ->
      (new Weaver.App(a.id, a.version, a.name) for a in list)
    )

  # Load given app from server
  @load: (id, version) ->
    Weaver.getCoreManager().getApp(id, version)

module.exports = WeaverApp
