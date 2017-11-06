cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')

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

  Then this function should return all subs of Area, because that is where
  the relation may point to:
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
    for range in @relationDefinition.range
      totalRanges.push(range)
      totalRanges.concat(addSubRange(range))

    totalRanges

  # Check if relation is allowed according to definition
  _checkCorrectClass: (node) ->
    range = @_getAllRanges()
    if range? and not range.includes(node.className)
      throw new Error("Model #{@className} is not allowed to have relation #{@modelKey} to #{node.className or 'an unspecified class'}")

  add: (node, relId, addToPendingWrites = true) ->
    @_checkCorrectClass(node)
    super(node, relId, addToPendingWrites)

  update: (oldNode, newNode) ->
    @_checkCorrectClass(newNode)
    super(oldNode, newNode)

module.exports = WeaverModelRelation
