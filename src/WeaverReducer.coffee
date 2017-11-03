###

    WEAVER STATE MANAGEMENT

###

# state:
#   nodes:
#     id_1:
#       relations:
#         relKey: [ 'id_2', 'id_3' ]
#       attrs:
#         attrKey: [ 'id_4' ]
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


initialState =
  nodes:      {}
  attributes: {}
  relations:  {}

module.exports = (state = initialState, action) ->
  switch (action.type)
    when 'ADD_NODE'
      newNodes = {}
      newNodes[action.id] = action.node
      Object.assign({}, state, nodes: Object.assign({}, state.nodes, newNodes))
    when 'SET_ATTRIBUTE'
      if state.attributes[action.id]
        state.attributes[action.id].value = action.value
    when 'ADD_ATTRIBUTE'
      state.attributes[action.id] = action.node
    when 'SET_RELATION'
      if state.relations[action.id]
        state.relations[action.id] = action.node
    when 'ADD_RELATION'
      state.relations[action.id] = action.node
    else
      state
