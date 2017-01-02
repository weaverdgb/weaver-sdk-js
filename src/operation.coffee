Code = require('weaver-commons').WriteOperation.Code

class NodeOperation

  constructor: (@node) ->

  create: ->
    @op = {code: Code.CREATE_NODE, id: @node.nodeId}

  setAttribute: (attribute, value) ->
    @op = {code: Code.UPDATE_NODE_ATTRIBUTE, id: @node.nodeId, attribute, value}

  unsetAttribute: (attribute) ->
    @op = {code: Code.REMOVE_NODE_ATTRIBUTE, id: @node.nodeId, attribute}


module.exports=
  Node: NodeOperation