cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')
_           = require('lodash')
cjson       = require('circular-json')

class WeaverModelRelation extends Weaver.Relation

  _getClassName: (node) ->
    node.className

  # Check if relation is allowed according to definition
  _assertCorrectClass: (to) ->
    to = to.toNode if to instanceof Weaver.Relation.Record
    if to instanceof Weaver.ModelClass or to instanceof Weaver.DefinedNode
      defs = to.getDefinitions()
      modelKey = @owner._getModelKey(@relationKey, defs...) or @modelKey
      found = @owner.getToRanges(modelKey, to) if modelKey?
      if !found? or found.length is 0
        allowed = JSON.stringify(@owner.getRanges(modelKey)) if modelKey?
        throw new Error("""Model #{@className} is not allowed to have relation #{modelKey} to #{to.id()} 
                           of def #{JSON.stringify(defs)}, allowed ranges are #{allowed}""")

  add: (node, relId, addToPendingWrites = true) ->
    @_assertCorrectClass(node)
    super(node, relId, addToPendingWrites)

  update: (oldNode, newNode) ->
    @_assertCorrectClass(newNode)
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
