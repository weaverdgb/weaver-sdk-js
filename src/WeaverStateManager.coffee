Weaver      = require('./Weaver')
actions     = require('./WeaverStateActions')
createStore = require('redux').createStore


normalizeNode = (node)->
  console.log('&&')
  console.log(node)
  normedNode = {nodeId: node.nodeId}

  normedNode.relations = {}
  for key, relation of node.relations
    normedNode.relations[key] = []
    for objId of relation.nodes
      normedNode.relations[key].push(relation.relationNodes[objId].nodeId)

  normedNode.attributes = {}
  for key, attr of node.attributes
    normedNode.attributes[key] = []
    normedNode.attributes[key].push(attr[0].nodeId)
  normedNode

normalizeRelation = (srcUid, targetUid, nodeId, key)->
  { srcUid, targetUid, nodeId, key }

normalizeAttribute = (nodeId, value, key, dataType)->
  { nodeId, value, key, dataType }

class StateManager
  constructor: ->
    @store = createStore(Weaver.Reducer)

    listener = =>
      @repository = @store.getState()
    @store.subscribe(listener)

    @repository = @store.getState()
    @

  storeNode: (node)->
    # console.log(node)
    @storeRelations(node)
    @storeAttributes(node)

    normedNode = normalizeNode(node)
    @store.dispatch(actions.addNode(normedNode))

  getNode: (id) ->
    state = @store.getState()
    state.nodes[id]

  storeRelations: (node)->
    for key, relation of node.relations
      for id of relation.nodes
        normedRel = normalizeRelation(node.nodeId, id, relation.relationNodes[id].nodeId, key)
        @store.dispatch(actions.addRelation(normedRel))

  storeAttributes: (node)->
    for key, attr of node.attributes
      normedAttr = normalizeAttribute(attr[0].nodeId, attr[0].value, attr[0].key, attr[0].dataType)
      @store.dispatch(actions.addAttribute(normedAttr))

  getState: ->
    @repository = @store.getState()

  wipeStore: ->
    @store.dispatch(actions.wipeStore())


module.exports = StateManager
