Weaver = require('./Weaver')
cuid   = require('cuid')
util   = require('./util')

NodeOperation = (node) ->
  if Weaver.instance?
    timestamp = Weaver.getCoreManager().serverTime()
  else
    timestamp = new Date().getTime()

  createNode: (graph)->
    {
      timestamp
      action: "create-node"
      id: node.id()
      graph: graph
    }

  removeNode: (graph)->
    {
      timestamp
      cascade: true
      action: "remove-node"
      id: node.id()
      removeId: cuid()
      removeGraph: graph
    }

  removeNodeUnrecoverable: (graph) ->
    {
      timestamp
      cascade: true
      action: "remove-node-unrecoverable"
      id: node.id()
      removeId: cuid()
      removeGraph: graph
    }

  createAttribute: (key, value, datatype, replaces, ignoreConcurrentReplace, graph) ->
    replaceId = null
    replaceId = cuid() if replaces?

    {
      timestamp
      action: "create-attribute"
      id: cuid()
      sourceId: node.id()
      key
      value
      datatype
      replacesId: replaces
      replaceId
      traverseReplaces: ignoreConcurrentReplace if replaces? and ignoreConcurrentReplace?
      graph: graph
    }

  removeAttribute: (id) ->
    {
      timestamp
      cascade: true
      action: "remove-attribute"
      id: id
      removeId: cuid()
    }

  createRelation: (key, to, id, replaces, ignoreConcurrentReplace) ->
    replacesId = replaces.id() if !util.isString(replaces) if replaces?
    replaceId = null
    replaceId = cuid() if replaces?
    throw new Error("Unable to set relation #{key} from #{node.id()} to null node") if !to?
    {
      timestamp
      action: "create-relation"
      id
      sourceId: node.id()
      key
      targetId: to.id()
      replacesId: replacesId
      replaceId
      traverseReplaces: ignoreConcurrentReplace if replaces? and ignoreConcurrentReplace?
      graph: node.getGraph()
      targetGraph: to.getGraph()
      replacesGraph: replaces.getGraph() if replaces.getGraph()? if replaces
    }

  removeRelation: (id) ->
    {
      timestamp
      cascade: true
      action: "remove-relation"
      id
      removeId: cuid()
    }

module.exports=
  Node: NodeOperation
