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
    to = to.toNode if to instanceof Weaver.Relation.Record
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
      return true if @model.classList[range].className is constructor.className and range is constructor.classId()
    throw new Error("Model #{@className} is not allowed to have relation #{@modelKey} to instance"+
      " of def #{constructor.className}.")

  add: (node, relId, addToPendingWrites = true) ->
    @_checkCorrectClass(node)
    super(node, relId, addToPendingWrites)

  update: (oldNode, newNode) ->
    @_checkCorrectClass(newNode)
    super(oldNode, newNode)

  load: ->
    new Weaver.ModelQuery(@model)
    .disableKeyMapping()
    .restrict(@owner)
    .selectOut(@key, '*')
    .find()
    .then((nodes)=>
      reloadedRelation = nodes[0].nodeRelation(@key)
      @_records = reloadedRelation.allRecords()
      reloadedRelation.all()
    )

module.exports = WeaverModelRelation
