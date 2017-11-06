module.exports =
  addNode: (node)->
    type: 'ADD_NODE',
    nodeId: node.nodeId,
    node: node

  addAttribute: (node)->
    type: 'ADD_ATTRIBUTE'
    nodeId:   node.nodeId
    node: node
  setAttribute: (id, val)->
    type: 'SET_ATTRIBUTE'
    id:   id
    val:  val

  addRelation: (node)->
    type:   'ADD_RELATION'
    nodeId: node.nodeId
    node:   node

  setRelation: (node)->
    type:   'SET_RELATION'
    nodeId: node.nodeId
    node:   node

  wipeStore: ->
    type: 'WIPE_STORE'
