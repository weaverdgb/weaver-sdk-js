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

  createAttribute: (key, value, datatype, replaces, ignoreConcurrentReplace) ->
    replaceId = null
    replaceId = cuid() if replaces?

    console.log ignoreConcurrentReplace

    {
      timestamp
      action: "create-attribute"
      id: cuid()
      sourceId: node.id()
      key
      value
      datatype
      replacesId: replaces if not ignoreConcurrentReplace
      replaceId
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
    {
      timestamp
      action: "create-relation"
      id
      sourceId: node.id()
      key
      targetId: to
      replacesId: replaces if not ignoreConcurrentReplace
      replaceId
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
