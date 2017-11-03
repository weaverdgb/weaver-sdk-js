cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')

class WeaverModel

  constructor: (@definition) ->
    return

  # Load given model from server
  @load: (name, version) ->
    Weaver.getCoreManager().getModel(name, version)

module.exports = WeaverModel
