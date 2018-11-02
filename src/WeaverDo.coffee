cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')

class WeaverDo

  @removeKeepUpdateAdd: (node, key, to, previous=undefined) ->

    nodeEql = (a, b)->
      return false if !a?
      return false if !b?
      return a.id() is b.id() and a.getGraph() is b.getGraph()

    olds = node.relation(key).all()
    
    return Promise.map(olds, (old)->node.relation(key).remove(old)) if !to?
    return Promise.resolve() for old in olds when nodeEql(to, old)
    if previous?
      node.relation(key).update(old, to) for old in olds when nodeEql(old, previous)
      node.save()
    else
      node.relation(key).add(to)
      node.save()

  @batchRelationRemove: (nodes, key, to, writes = []) ->
    
    for node in nodes
      for rel in node.relation(key).relationNodes
        if rel.to().id() is to.id() and rel.to().getGraph() is to.getGraph()

          writes.push({
            timestamp: new Date().getTime()
            cascade: false
            action: "remove-relation"
            id: rel.id()
            graph: rel.getGraph()
            removeId: cuid()
            removeGraph: rel.getGraph()
          })

    writes

  @requireAttribute: (node, key, value)->
    if not value?
      return node.get(key)?
    return node.get(key)? and node.get(key) is value

  @requireNodeCount: (node, key, count)->
    node.relation(key).all().length is count

  @hasRelationTo: (node, key, to)->
    for candidate in node.relation(key).all() 
      if candidate.id() is to.id() and candidate.getGraph() is to.getGraph()
        return true
    false

# Export
module.exports = WeaverUser
