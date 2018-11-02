_ = require 'lodash'

class WeaverNodeList extends Array

  constructor: (arr = [])->
    super()
    @push(el) for el in arr # allows WeaverNodeList to be constructed like so: new WeaverNodeList(Array)
    @

  _getArrayNestedByRel: (rel, arr = @) ->
    arr.map((n) => n.relation(rel).all())
    .map((targets) => targets._getArrayNestedByRel(rel, targets))
    .concat(arr)

  flattenByRelation: (rel)->
    new WeaverNodeList(_.flattenDeep(@_getArrayNestedByRel(rel)))
    .reduceDeepestLoaded() # default, remove this to include multiple refs for single node

  getRelationDepth = (node, rel, currentDepth = 0)->
    return -1 if not node
    if node._loaded
      getRelationDepth(node.relation(rel).first(), rel, ++currentDepth)
    else
      currentDepth

  deeperLoaded = (nodes, rel) ->
    nodes.reduce((n1, n2)->
      if getRelationDepth(n1, rel) > getRelationDepth(n2, rel)
        n1
      else
        n2
    )

  reduceDeepestLoaded: (rel)-> # in case of duplicates, keep the node which is most deeply loaded
    resultsMap = {}
    @map((n)->
      resultsMap[n.id()] = deeperLoaded([resultsMap[n.id()], n], rel)
    )
    new WeaverNodeList(_.values(resultsMap))

  reduceOnlyLoaded: ->
    @filter((n)-> n._loaded)

  ###
    TODO
    unflattenByRelation: (relsToBuild) ->
  ###

# Export
module.exports = WeaverNodeList
