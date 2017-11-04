cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')

class WeaverModelRelation extends Weaver.Relation

  # Check if relation is allowed according to definition
  _checkCorrectClass: (node) ->
    range = @relationDefinition.range
    if range? and not range.includes(node.className)
      throw new Error("Model #{@className} is not allowed to have relation #{@modelKey} to #{node.className or 'an unspecified class'}")

  add: (node, relId, addToPendingWrites = true) ->
    @_checkCorrectClass(node)
    super(node, relId, addToPendingWrites)

  update: (oldNode, newNode) ->
    @_checkCorrectClass(newNode)
    super(oldNode, newNode)

module.exports = WeaverModelRelation
