Action    = {}
Signature = {}

# Helper method
define = (action, attributes) ->
  Signature[action] = {}
  Signature[action][attribute] = null for attribute in attributes
  action

Action.CREATE_NODE            = define 'create-node',        ['id']
Action.REMOVE_NODE            = define 'remove-node',        ['id']
Action.CREATE_ATTRIBUTE       = define 'create-attribute',   ['id', 'key', 'value', 'datatype']
Action.REMOVE_ATTRIBUTE       = define 'remove-attribute',   ['id', 'key']
Action.CREATE_RELATION        = define 'create-relation',    ['from', 'key', 'to' ]          # only one relation with this key can exist between these two node ids
Action.REMOVE_RELATION        = define 'remove-relation',    ['from', 'key', 'to' ]
Action.OBJECTIFY_RELATION     = define 'objectify-relation', ['from', 'key', 'to', 'id' ]
Action.MERGE_NODES            = define 'merge-nodes',        ['id_into', 'id_merge']

module.exports = {Action, Signature}