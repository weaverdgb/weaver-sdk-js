cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')

class WeaverModelClass extends Weaver.Node

  constructor: (nodeId) ->
    super(nodeId)
    @buildByDefinition()

  buildByDefinition: ->
    console.log @modelClass

module.exports = WeaverModelClass
