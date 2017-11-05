###

    WEAVER STATE MANAGEMENT

###

# state:
#   nodes:
#     id_1:
#       relations:
#         relKey: [ 'id_2', 'id_3' ]
#       attrs: [ 'id_4' ]
#   relations:
#     rel_id_1:
#       sourceUid: 'id_1'
#       targetId: 'id_2'
#       keyLabel: 'link'
#   attributes:
#     attr_id_1:
#       sourceUid: 'id_1'
#       keyLabel: 'name'
#       value:    'Node 1'
#
#


initialState =
  nodes:      {}
  attributes: {}
  relations:  {}

module.exports = (state = initialState, action) ->
  switch (action.type)
    when 'ADD_NODE'
      newNodes = {}
      newNodes[action.nodeId] = action.node
      Object.assign(state, nodes: Object.assign({}, state.nodes, newNodes))
    when 'ADD_ATTRIBUTE'
      newNodes = {}
      newNodes[action.nodeId] = action.node
      Object.assign(state, attributes: Object.assign({}, state.attributes, newNodes))
    when 'ADD_RELATION'
      newNodes = {}
      newNodes[action.nodeId] = action.node
      Object.assign(state, relations: Object.assign({}, state.relations, newNodes))
    else
      state
