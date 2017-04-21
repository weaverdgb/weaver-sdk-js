Action = require('./WriteOperation').Action

NodeOperation = (node) ->

  timestamp   = node.getWeaver().getCoreManager().serverTime()

  # Silent operations (can be bundled)

  create: ->
    {
      timestamp
      action: Action.CREATE_NODE
      id: node.id()
    }

  destroy: ->
    {
      timestamp
      action: Action.REMOVE_NODE
      id: node.id()
    }

  setAttribute: (key, value, datatype) ->
    {
      timestamp
      action: Action.CREATE_ATTRIBUTE
      id: node.id()
      key
      value
      datatype
    }

  updateAttribute: (key, value, datatype) ->
    {
      timestamp
      action: Action.UPDATE_ATTRIBUTE
      id: node.id()
      key
      value
      datatype
    }

  unsetAttribute: (key) ->
    {
      timestamp
      action: Action.REMOVE_ATTRIBUTE
      id: node.id()
      key
    }

  createRelation: (key, to) ->
    {
      timestamp
      action: Action.CREATE_RELATION
      from: node.id()
      key
      to
    }

  updateRelation: (key, oldTo, newTo) ->
    {
      timestamp
      action: Action.UPDATE_RELATION
      from: node.id()
      key
      oldTo
      newTo
    }

  removeRelation: (key, to) ->
    {
      timestamp
      action: Action.REMOVE_RELATION
      from: node.id()
      key
      to
    }

  mergeNodes: (idInto, idMerge) ->
    {
      timestamp
      action: Action.MERGE_NODES
      idInto
      idMerge
    }

  # Operations that return an answer

  incrementAttribute: (key, value) ->
    {
      timestamp
      action: Action.INCREMENT_ATTRIBUTE
      id: node.id()
      key
      value
    }

  objectifyRelation: (key, to, id) ->
    {
      timestamp
      action: Action.OBJECTIFY_RELATION
      from: node.id()
      key
      to
      id
    }

module.exports=
  Node: NodeOperation
