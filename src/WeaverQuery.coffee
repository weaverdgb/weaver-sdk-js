# Libs
cuid = require('cuid')

module.exports =
class WeaverRelation

  constructor: () ->
    @nodeId = cuid()      # Generate random id
    @attributes = {}      # Store all attributes in this object

  query: ->


