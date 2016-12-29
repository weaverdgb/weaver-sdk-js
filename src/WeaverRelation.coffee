# Libs
cuid = require('cuid')

module.exports =
class WeaverQuery

  constructor: () ->
    @nodeId = cuid()      # Generate random id
    @attributes = {}      # Store all attributes in this object

  add: ->

  remove: ->

  query: ->