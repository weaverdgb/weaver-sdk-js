cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')

class WeaverModelClass extends Weaver.Node

  constructor: (nodeId) ->
    super(nodeId)
    @className = @constructor.name

  _getAttributeKey: (field) ->
    if not @classDefinition.attributes[field]?
      throw new Error("Field #{field} is not valid on this #{@className} model")

    @classDefinition.attributes[field].key or field

  get: (field) ->
    super(@_getAttributeKey(field))

  set: (field, value) ->
    super(@_getAttributeKey(field), value)


module.exports = WeaverModelClass
