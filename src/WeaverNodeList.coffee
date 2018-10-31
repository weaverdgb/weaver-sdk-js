_ = require 'lodash'

class WeaverNodeList extends Array

  flattenByRelation: (relsToTraverse = [], onlyLoaded = true)->
    results = new WeaverNodeList()

    flatten = (node, relsToTraverse, onlyLoaded, current = new WeaverNodeList())->
      current.push(node)
      for key of node.relations?() when relsToTraverse.indexOf(key) isnt -1
        if node.relation(key)?.first()?._loaded or (not onlyLoaded and node.relation(key)?.first()?)
          for rel in node.relation(key).all()
            flatten(rel, relsToTraverse, onlyLoaded, current)
      current

    for node in @
      results = results.concat(flatten(node, relsToTraverse, onlyLoaded))
      flatten(node, relsToTraverse, onlyLoaded)

    results

  ###
    TODO
    deepenByRelation: (relsToTraverse) ->
  ###

# Export
module.exports = WeaverNodeList
