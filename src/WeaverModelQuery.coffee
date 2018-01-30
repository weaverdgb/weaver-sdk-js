cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')

class WeaverModelQuery extends Weaver.Query

  constructor: (@model = Weaver.currentModel(), target) ->
    super(target)

  getNodeIdFromStringOrNode: (node) ->
    try
      super(node)
    catch err
      if node.model?
        {
          id: "#{node.model.definition.name}:#{node.className}"
          graph: node.model.getGraph()
        }
      else
        throw err


  class: (modelClass) ->
    # Define constructor function
    @useConstructor((node) =>
      defs = (def.id() for def in node.relation(@model.getMemberKey()).all())
      if modelClass.classId() in defs
        modelClass
      else
        Weaver.Node
    )
    @hasRelationOut(@model.getMemberKey(), Weaver.Node.getFromGraph(modelClass.classId(), @model.getGraph()))

  # Key is composed of Class.modelAttribute
  _mapKeys: (keys, source) ->
    databaseKeys = []
    for key in keys
      if [@model.getMemberKey(), '*'].includes(key)
        databaseKeys.push(key)
      else
        if key.indexOf(".") is -1
          throw new Error("Key should be in the form of ModelClass.key")

        [className, modelKey] = key.split(".")
        modelClass = @model[className]
        definition  = modelClass.classDefinition

        databaseKeys.push(definition[source]?[modelKey]?.key or modelKey)

    databaseKeys

  _mapKey: (key, source) ->
    @_mapKeys([key], source)[0]

  _addAttributeCondition: (key, condition, value) ->
    super(@_mapKey(key, "attributes"), condition, value)

  _addRelationCondition: (key, condition, value) ->
    super(@_mapKey(key, "relations"), condition, value)

  _addRecursiveCondition: (op, relation, node, includeSelf) ->
    super(op, @_mapKey(relation, "relations"), node, includeSelf)

  equalTo: (key, value) ->
    super(@_mapKey(key, "attributes"), value)

  order: (keys, ascending) ->
    super(@_mapKeys(keys, "attributes"), ascending)

  select: (keys...) ->
    super(key) for key in @_mapKeys(keys, "attributes")
    @

  selectOut: (keys...) ->
    # Note that calling selectOut(1, 2) differs from calling selectOut(1);
    # selectOut(2). Arrayity matters
    super(@_mapKeys(keys, "relations")...)
    @

  selectRecursiveOut: (keys...) ->
    super(key) for key in @_mapKeys(keys, "relations")
    @

  find: (Constructor) ->
    # Always get the member relation to map to the correct modelclass
    @alwaysLoadRelations(@model.getMemberKey())

    super(Constructor)

module.exports = WeaverModelQuery
