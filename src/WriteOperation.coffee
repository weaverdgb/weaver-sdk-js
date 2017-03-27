Action    = {}
Signature = {}

# Helper method
define = (action, attributes) ->
  Signature[action] = {}
  Signature[action][attribute] = null for attribute in attributes
  action

Action.CREATE_NODE            = define 'create-node',         ['id']
Action.REMOVE_NODE            = define 'remove-node',         ['id']
Action.CREATE_ATTRIBUTE       = define 'create-attribute',    ['id', 'key', 'value', 'datatype']
Action.UPDATE_ATTRIBUTE       = define 'update-attribute',    ['id', 'key', 'value', 'datatype']
Action.REMOVE_ATTRIBUTE       = define 'remove-attribute',    ['id', 'key']
Action.CREATE_RELATION        = define 'create-relation',     ['from', 'key', 'to' ]          # only one relation with this key can exist between these two node ids
Action.UPDATE_RELATION        = define 'update-relation',     ['from', 'key', 'oldTo', 'newTo' ]
Action.REMOVE_RELATION        = define 'remove-relation',     ['from', 'key', 'to' ]
Action.MERGE_NODES            = define 'merge-nodes',         ['idInto', 'idMerge']

# Operations that return an answer
# these should be the only operation in the submitted array
Action.INCREMENT_ATTRIBUTE    = define 'increment-attribute', ['id', 'key', 'value']
Action.OBJECTIFY_RELATION     = define 'objectify-relation',  ['from', 'key', 'to', 'id' ]

module.exports = {Action, Signature}