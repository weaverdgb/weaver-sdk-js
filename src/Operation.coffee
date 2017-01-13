Action = require('weaver-commons').WriteOperation.Action

NodeOperation = (node) ->

  create: ->
    {action: Action.CREATE_NODE, id: node.id()}

  destroy: ->
    {action: Action.REMOVE_NODE, id: node.id()}

  setAttribute: (key, value, datatype) ->
    {action: Action.UPDATE_ATTRIBUTE, id: node.id(), key, value, datatype}

  unsetAttribute: (key) ->
    {action: Action.REMOVE_ATTRIBUTE, id: node.id(), key}

  createRelation: (key, to) ->
    {action: Action.CREATE_RELATION, from: node.id(), key, to}

  removeRelation: (key, to) ->
    {action: Action.REMOVE_RELATION, from: node.id(), key, to}

  objectifyRelation: (key, to, id) ->
    {action: Action.OBJECTIFY_RELATION, from: node.id(), key, to, id}

  mergeNodes: (id_into, id_merge) ->
    {action: Action.MERGE_NODES, id_into, id_merge}

module.exports=
  Node: NodeOperation