Weaver = require('./Weaver')

class NodeSynchronizer
  constructor: ->
    @nodes = {}
    @actions = {
      'node.syncing':          @addNode.bind(@)
      'node.released':         @removeNode.bind(@)
      'node.destroyed':        (nodeId) => @nodes[nodeId] = [] if @nodes[nodeId]?
      'node.attribute.set':    (data) => @nodeAttributeSet(data.node, data.field)
      'node.attribute.update': (data) => @nodeAttributeSet(data.node, data.field)
      'node.attribute.unset':  (data) => @nodeAttributeUnset(data.node, data.field)
      'node.relation.add':     (data) => @nodeRelationAdd(data.node, data.key, data.target)
      'node.relation.update':  (data) => @nodeRelationAdd(data.node, data.key, data.oldTarget, data.target)
      'node.relation.remove':  (data) => @nodeRelationAdd(data.node, data.key, data.target)
    }


  start: ->
    @token = Weaver.subscribe('node', (msg, data) =>
      @actions[msg](data) if @actions[msg]?
    )

  stop: ->
    Weaver.unsubscribe(@token)
    @token = null
    @nodes = {}

  getNodes: (id) ->
    @nodes[id] = @nodes[id] or []
    @nodes[id]

  getToSyncNodes: (changedNode) ->
    @getNodes(changedNode.id()).filter((n) -> n isnt changedNode)

  addNode: (node) ->
    @getNodes(node.id()).push(node) if @getNodes(node.id()).indexOf(node) is -1

  removeNode: (node) ->
    nodes = @getNodes(node.id())
    index = nodes.indexOf(node)
    if index > -1
      nodes.splice(index, 1)

  nodeAttributeSet: (changedNode, field) ->
    for n in @getToSyncNodes(changedNode)
      n.attributes[field] = changedNode.attributes[field]

  nodeAttributeUnset: (changedNode, field) ->
    for n in @getToSyncNodes(changedNode)
      delete n.attributes[field]

  nodeRelationAdd: (changedNode, key, addedNode) ->
    for n in @getToSyncNodes(changedNode)
      n.relations[key].nodes[addedNode.id()]         = changedNode.relations[key].nodes[addedNode.id()]
      n.relations[key].relationNodes[addedNode.id()] = changedNode.relations[key].relationNodes[addedNode.id()]

  nodeRelationUpdate: (changedNode, key, oldNode, newNode) ->
    for n in @getToSyncNodes(changedNode)
      delete n.relations[key].nodes[oldNode.id()]
      delete n.relations[key].relationNodes[oldNode.id()]

      n.relations[key].nodes[newNode.id()]         = changedNode.relations[key].nodes[newNode.id()]
      n.relations[key].relationNodes[newNode.id()] = changedNode.relations[key].relationNodes[newNode.id()]

  nodeRelationRemove: (changedNode, key, removedNode) ->
    for n in @getToSyncNodes(changedNode)
      delete n.relations[key].nodes[removedNode.id()]
      delete n.relations[key].relationNodes[removedNode.id()]

module.exports = NodeSynchronizer
