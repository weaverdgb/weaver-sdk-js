_ = require 'lodash'

class WeaverNodeList extends Array

  constructor: (arr = [])->
    super()
    @push(el) for el in arr
    @

  deeperLoaded = (nodes, rel) ->
    getRelDepth = (node, curr = 0)->
      if node._loaded
        getRelDepth(node.relation(rel).first(), ++curr)
      else
        curr
    nodes.reduce((n1, n2)->
      if getRelDepth(n1) > getRelDepth(n2)
        n1
      else
        n2
    )

  flattenByRelation: (relToTraverse)->
    results = []

    flatten = (node, relToTraverse, current = [])->
      current.push(node)
      for key of node.relations?() when relToTraverse is key
        if node.relation(key)?.first()?
          for rel in node.relation(key).all()
            flatten(rel, relToTraverse, current)
      current

    for node in @
      results = results.concat(flatten(node, relToTraverse))
    resultsMap = {}

    results.map((n)->
      if resultsMap[n.id()]
        resultsMap[n.id()] = deeperLoaded([resultsMap[n.id()], n], relToTraverse)
      else
        resultsMap[n.id()] = n
    )
    new WeaverNodeList(_.values(resultsMap))

  ###
    TODO
    unflattenByRelation: (relsToBuild) ->
  ###

  reduceOnlyLoaded: ->
    @filter((n)-> n._loaded)

# Export
module.exports = WeaverNodeList
