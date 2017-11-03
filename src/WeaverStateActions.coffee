module.exports =
  addNode: (node)->
    type: 'ADD_NODE',
    id:   node.id,
    node: node

  addAttribute: (node)->
    type: 'ADD_ATTRIBUTE'
    id:   node.id
    node: node
  setAttribute: (id, val)->
    type: 'SET_ATTRIBUTE'
    id:   id
    val:  val

  addRelation: (node)->
    type: 'ADD_RELATION'
    id:   node.id
    node: node
  setRelation: (node)->
    type: 'SET_RELATION'
    id:   node.id
    node: node
