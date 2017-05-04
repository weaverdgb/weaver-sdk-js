Action    = {}
Signature = {}

# Helper method
define = (action, attributes) ->
  Signature[action] = {}
  Signature[action][attribute] = null for attribute in attributes
  action

Action.CREATE_NODE            = define 'create-node',         ['timestamp', 'id']
Action.REMOVE_NODE            = define 'remove-node',         ['timestamp', 'id']
Action.CREATE_ATTRIBUTE       = define 'create-attribute',    ['timestamp', 'id', 'key', 'value', 'datatype']
Action.UPDATE_ATTRIBUTE       = define 'update-attribute',    ['timestamp', 'id', 'key', 'value', 'datatype']
Action.REMOVE_ATTRIBUTE       = define 'remove-attribute',    ['timestamp', 'id', 'key']
Action.CREATE_RELATION        = define 'create-relation',     ['timestamp', 'from', 'key', 'to', 'id' ]          # only one relation with this key can exist between these two node ids
Action.UPDATE_RELATION        = define 'update-relation',     ['timestamp', 'from', 'key', 'oldTo', 'newTo' ]
Action.REMOVE_RELATION        = define 'remove-relation',     ['timestamp', 'from', 'key', 'to' ]
Action.MERGE_NODES            = define 'merge-nodes',         ['timestamp', 'idInto', 'idMerge']

# Operations that return an answer
# these should be the only operation in the submitted array
Action.INCREMENT_ATTRIBUTE    = define 'increment-attribute', ['timestamp', 'id', 'key', 'value']
Action.OBJECTIFY_RELATION     = define 'objectify-relation',  ['timestamp', 'from', 'key', 'to', 'id' ]

module.exports = {Action, Signature}