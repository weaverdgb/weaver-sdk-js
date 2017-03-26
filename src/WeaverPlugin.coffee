Weaver      = require('./Weaver')
CoreManager = Weaver.getCoreManager()

class WeaverPlugin

  constructor: (@name) ->

  @list: ->
    CoreManager.listPlugins()


module.exports = WeaverPlugin
