Weaver = require('./Weaver')
cuid   = require('cuid')

NodeOperation = (node) ->
  timestamp   = Weaver.getCoreManager().serverTime()

  createNode: ->
    {
      timestamp
      action: "create-node"
      id: node.id()
    }

  removeNode: ->
    {
      timestamp
      action: "remove-node"
      id: node.id()
      removeId: cuid()
    }

  createAttribute: (key, value, datatype, replaces) ->
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
    }

  removeAttribute: (id) ->
    {
      timestamp
      action: "remove-attribute"
      id: id
      removeId: cuid()
    }

  createRelation: (key, to, id, replaces) ->
    replaceId = null
    replaceId = cuid() if replaces?
    {
      timestamp
      action: "create-relation"
      id
      sourceId: node.id()
      key
      targetId: to
      replacesId: replaces
      replaceId
    }

  removeRelation: (id) ->
    {
      timestamp
      action: "remove-relation"
      id
      removeId: cuid()
    }

module.exports=
  Node: NodeOperation
