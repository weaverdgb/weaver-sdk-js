# Libs
cuid = require('cuid')

module.exports =
class WeaverACL

  constructor: () ->
    @nodeId = cuid()      # Generate random id
    @attributes = {}      # Store all attributes in this object

  add: ->

  remove: ->

  query: ->