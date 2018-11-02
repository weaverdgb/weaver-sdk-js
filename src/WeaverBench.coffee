cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')

class WeaverBench

  # Execte the operation on call
  @do: {
    onlyTo: (node, key, to) ->
      olds = node.relation(key).all()
      
      Promise.map(olds, (old)->
        node.relation(key).remove(old) if !WeaverBench.equals(to, node)
      ).then(->
        node.relation(key).add(to)
        node.save()
      )

  }

  @removeKeepUpdateAdd: (node, key, to, previous=undefined) ->

    olds = node.relation(key).all()
    
    return Promise.map(olds, (old)->node.relation(key).remove(old)) if !to?
    return Promise.resolve() for old in olds when WeaverBench.equals(to, old)
    if previous?
      node.relation(key).update(old, to) for old in olds when WeaverBench.equals(old, previous)
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

  @equals: (a, b) ->
    return false if !a? or ! a instanceof Weaver.Node
    return false if !b? or ! b instanceof Weaver.Node
    return a.id() is b.id() and a.getGraph() is b.getGraph()

# Export
module.exports = WeaverBench
