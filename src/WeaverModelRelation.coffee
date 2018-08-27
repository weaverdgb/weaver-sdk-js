cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')
_           = require('lodash')
cjson       = require('circular-json')

class WeaverModelRelation extends Weaver.Relation

  _getClassName: (node) ->
    node.className

  # Check if relation is allowed according to definition
  _checkCorrectClass: (to) ->
    defs = []
    if to instanceof Weaver.ModelClass or to instanceof Weaver.DefinedNode 
      defs = to.getDefinitions()
    else
      return

    found = @owner.getToRanges(@modelKey, to)
    allowed = @owner.getRanges(@modelKey)
    return true if found? and found.length > 0
    throw new Error("Model #{@className} is not allowed to have relation #{@modelKey} to #{to.id()}"+
                    " of def #{JSON.stringify(defs)}, allowed ranges are #{JSON.stringify(allowed)}")

  _checkCorrectConstructor: (constructor) ->
    for range in @owner.getRanges(@modelKey)
      return true if @model.classList[range] is constructor
    throw new Error("Model #{@className} is not allowed to have relation #{@modelKey} to instance"+
      " of def #{constructor.className}.")

  add: (node, relId, addToPendingWrites = true) ->
    @_checkCorrectClass(node)
    super(node, relId, addToPendingWrites)

  update: (oldNode, newNode) ->
    @_checkCorrectClass(newNode)
    super(oldNode, newNode)

  load: (constructor)->
    @_checkCorrectConstructor(constructor)
    super(constructor)

module.exports = WeaverModelRelation
