Weaver = require('./Weaver')
cuid   = require('cuid')

NodeOperation = (node) ->
  if Weaver.instance?
    timestamp = Weaver.getCoreManager().serverTime()
  else
    timestamp = new Date().getTime()

  createNode: ->
    {
      timestamp
      action: "create-node"
      id: node.id()
    }

  removeNode: ->
    {
      timestamp
      cascade: true
      action: "remove-node"
      id: node.id()
      removeId: cuid()
    }

  removeNodeUnrecoverable: ->
    {
      timestamp
      cascade: true
      action: "remove-node-unrecoverable"
      id: node.id()
      removeId: cuid()
    }

  createAttribute: (key, value, datatype, replaces, ignoreConcurrentReplace) ->
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
    replaceId = null
    replaceId = cuid() if replaces?
    throw new Error("Unable to set relation #{key} from #{node.id()} to null node") if !to?
    {
      timestamp
      action: "create-relation"
      id
      sourceId: node.id()
      key
      targetId: to
      replacesId: replaces
      replaceId
      traverseReplaces: ignoreConcurrentReplace if replaces? and ignoreConcurrentReplace?
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
