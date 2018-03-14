cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')
_           = require('lodash')
cjson       = require('circular-json')

class WeaverModelRelation extends Weaver.Relation

  _getClassName: (node) ->
    node.className

  # Check if relation is allowed according to definition
  _checkCorrectClass: (node) ->
    found = @parent.getToRanges(@modelKey, node)
    allowed = @parent.getRanges(@modelKey)
    return true if found.length > 0
    throw new Error("Model #{@className} is not allowed to have relation #{@modelKey} to #{node.id()}, allowed ranges are #{JSON.stringify(allowed)}")

  add: (node, relId, addToPendingWrites = true) ->
    @_checkCorrectClass(node)
    super(node, relId, addToPendingWrites)

  update: (oldNode, newNode) ->
    @_checkCorrectClass(newNode)
    super(oldNode, newNode)

module.exports = WeaverModelRelation
