Weaver      = require('./Weaver')
actions = require('./WeaverStateActions')
weaver = Weaver.getInstance()

normalizeNode = (node)->
  normedNode = {id: node.id()}
  normedNode.relations = {}
  for key, relation of node.relations
    normedNode.relations[key] = []
    for objId of relation.nodes
      normedNode.relations[key].push(relation.relationNodes[objId].nodeId)
  normedNode

normalizeRelation = (relNode)->
  normedRel = {id: relNode.nodeId}

addRelations = (node)->
  for key, relation of node.relations
    # console.log(relation)
    0


StateManager =
  addNode: (node)->
    addRelations(node)
    normedNode = normalizeNode(node)
    weaver.store.dispatch(actions.addNode(normedNode))

  getNode: (id) ->
    state = weaver.store.getState()
    state.nodes[id]

  # addRelation:


module.exports = StateManager
