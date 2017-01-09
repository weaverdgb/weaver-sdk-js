Action = require('weaver-commons').WriteOperation.Action

class NodeOperation

  constructor: (@node) ->

  create: ->
    @op = {action: Action.CREATE_NODE, id: @node.nodeId}

  remove: ->
    @op = {action: Action.REMOVE_NODE, id: @node.nodeId}

  setAttribute: (key, value, datatype) ->
    @op = {action: Action.UPDATE_ATTRIBUTE, id: @node.nodeId, key, value, datatype}

  unsetAttribute: (key) ->
    @op = {action: Action.REMOVE_ATTRIBUTE, id: @node.nodeId, key}

  createRelation: (key, to) ->
    @op = {action: Action.CREATE_RELATION, from: @node.nodeId, key, to}

  removeRelation: (key, to) ->
    @op = {action: Action.REMOVE_RELATION, from: @node.nodeId, key, to}

  objectifyRelation: (key, to, id) ->
    @op = {action: Action.OBJECTIFY_RELATION, from: @node.nodeId, key, to, id}

  mergeNodes: (id_into, id_merge) ->
    @op = {action: Action.MERGE_NODES, id_into, id_merge}

module.exports=
  Node: NodeOperation