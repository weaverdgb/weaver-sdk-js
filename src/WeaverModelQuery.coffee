cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')

class WeaverModelQuery extends Weaver.Query

  constructor: (@model = Weaver.currentModel(), target) ->
    super(target)

    # Define constructor function
    @useConstructor((node, owner, key)=>
      defs = (def.id() for def in node.relation(@model.getMemberKey()).all() when def.id().startsWith(@model.definition.name))
      if defs.length is 0
        Weaver.Node
      else if defs.length is 1
        [modelPart, classPart] = defs[0].split(":")
        @model.modelMap[modelPart][classPart]

      # First order node from resultset, no incoming relation to help decide
      else if not owner?

        if not @preferredConstructor?
          console.info("Could not choose contructing first order node between type #{JSON.stringify(defs)}")
          return Weaver.Node

        return @preferredConstructor
      else

        if not owner instanceof Weaver.ModelClass
          console.info("Could not choose contructing node between type #{JSON.stringify(defs)}")
          return Weaver.Node

        modelKey = owner.lookUpModelKey(key)

        ranges = owner.getToRanges(modelKey, node)
        if ranges.length < 1
          console.warn("Could not find a range for constructing second order node between type #{JSON.stringify(defs)}")
          return Weaver.Node
        else if ranges.length > 1
          console.warn("Could not pick from ranges #{JSON.stringify(ranges)} for constructing second order node between type #{JSON.stringify(defs)}")
          return Weaver.Node
        else 
          [modelName, className] = ranges[0].split(':')
          return @model.modelMap[modelName][className]
    )


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

  find: (@preferredConstructor) ->
    # Always get the member relation to map to the correct modelclass
    @alwaysLoadRelations(@model.getMemberKey())

    super()

module.exports = WeaverModelQuery
