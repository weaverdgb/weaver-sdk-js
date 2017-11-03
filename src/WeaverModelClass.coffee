cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')

class WeaverModelClass extends Weaver.Node

  constructor: (nodeId) ->
    super(nodeId)
    @buildByDefinition()

  buildByDefinition: ->
    return
    
module.exports = WeaverModelClass
