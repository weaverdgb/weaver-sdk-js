Action = require('./WriteOperation').Action

NodeOperation = (node) ->

  # Silent operations (can be bundled)

  create: ->
    {action: Action.CREATE_NODE, id: node.id()}

  destroy: ->
    {action: Action.REMOVE_NODE, id: node.id()}

  setAttribute: (key, value, datatype) ->
    {action: Action.CREATE_ATTRIBUTE, id: node.id(), key, value, datatype}

  updateAttribute: (key, value, datatype) ->
    {action: Action.CREATE_ATTRIBUTE, id: node.id(), key, value, datatype}

  unsetAttribute: (key) ->
    {action: Action.REMOVE_ATTRIBUTE, id: node.id(), key}

  createRelation: (key, to) ->
    {action: Action.CREATE_RELATION, from: node.id(), key, to}

  updateRelation: (key, oldTo, newTo) ->
    {action: Action.UPDATE_RELATION, from: node.id(), key, oldTo, newTo}

  removeRelation: (key, to) ->
    {action: Action.REMOVE_RELATION, from: node.id(), key, to}

  mergeNodes: (id_into, id_merge) ->
    {action: Action.MERGE_NODES, id_into, id_merge}

  # Operations that return an answer

  incrementAttribute: (key, value) ->
    {action: Action.INCREMENT_ATTRIBUTE, id: node.id(), key, value}

  objectifyRelation: (key, to, id) ->
    {action: Action.OBJECTIFY_RELATION, from: node.id(), key, to, id}

module.exports=
  Node: NodeOperation
