cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')
_           = require('lodash')
cjson       = require('circular-json')

class WeaverModelRelation extends Weaver.Relation

  ###
  If we have the following super/sub structure:
  - Area
    - Section
      - Country

  And the following relation definition of Person:
  - Person
    - livesIn:
        range: [Area]

  Then this function should return all subs of Area, because that is where the relation may point to:
  [Area, Section, Country]
  ###
  _getAllRanges: ->
    addSubRange = (range, ranges = []) =>
      for className, definition of @model.definition.classes
        if definition.super is range
          ranges.push(className)
          # Follow again for this subclass
          addSubRange(className, ranges)

      ranges

    totalRanges = []
    for range in @_getRangeKeys()
      totalRanges.push(range)
      totalRanges = totalRanges.concat(addSubRange(range))

    totalRanges

  _getRangeKeys: ->
    range = @relationDefinition.range
    if _.isArray(range)
      range
    else
      _.keys(range)

  _getClassName: (node) ->
    node.className

  getRange: (node)->
    defs = []
    if node instanceof Weaver.ModelClass
      defs = (def.id().split(":")[1] for def in node.nodeRelation(@model.getMemberKey()).all())
    else  
      defs = (def.id().split(":")[1] for def in node.relation(@model.getMemberKey()).all())

    # console.log(cjson.stringify(node.nodeRelation(@model.getMemberKey())))

    console.log('defs:')
    console.log(defs)
    ranges = @_getAllRanges()
    console.log('ranges:')
    console.log(ranges)


    # console.log(node.id())
    # console.log(to.constructor) for to in node.nodeRelation(@model.getMemberKey()).all()




    (def for def in defs)




  # Check if relation is allowed according to definition
  _checkCorrectClass: (node) ->
    return true if @getRange(node).length > 0
    throw new Error("Model #{@className} is not allowed to have relation #{@modelKey} to #{node.id()}, allowed ranges are #{JSON.stringify(@_getAllRanges())}")

  add: (node, relId, addToPendingWrites = true) ->
    @_checkCorrectClass(node) if node instanceof Weaver.ModelClass
    super(node, relId, addToPendingWrites)

  update: (oldNode, newNode) ->
    @_checkCorrectClass(newNode) if node instanceof Weaver.ModelClass
    super(oldNode, newNode)

module.exports = WeaverModelRelation
