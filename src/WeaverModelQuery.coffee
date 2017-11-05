cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')

class WeaverModelQuery extends Weaver.Query

  constructor: (@model = Weaver.currentModel(), target) ->
    super(target)

    # Define constructor function
    @useConstructor((node) =>
      if node.relation('_proto').first()?
        [modelName, className] = node.relation('_proto').first().id().split(":")
        @model[className]
      else
        Weaver.Node
    )

  class: (modelClass) ->
    @hasRelationOut("_proto", modelClass.classId())

  # Key is composed of Class.modelAttribute
  _mapKeys: (keys, source) ->
    databaseKeys = []
    for key in keys
      if ['_proto', '*'].includes(key)
        databaseKeys.push(key)
      else
        [className, modelKey] = key.split(".")
        modelClass = @model[className]
        defintion  = modelClass.classDefinition

        databaseKeys.push(defintion[source]?[modelKey]?.key or modelKey)

    databaseKeys

  _mapKey: (key, source) ->
    @_mapKeys([key], source)[0]

  _addCondition: (key, condition, value) ->
    super(@_mapKey(key, "attributes"), condition, value)

  equalTo: (key, value) ->
    super(@_mapKey(key, "attributes"), value)

  order: (keys, ascending) ->
    super(@_mapKeys(keys, "attributes"), ascending)

  select: (keys...) ->
    super(key) for key in @_mapKeys(keys, "attributes")

  selectOut: (keys...) ->
    super(key) for key in @_mapKeys(keys, "relations")

  selectRecursiveOut: (keys...) ->
    super(key) for key in @_mapKeys(keys, "relations")

  find: (Constructor) ->
    # Always get the _proto relation to map to the correct modelclass
    @selectOut('_proto')
    # @selectOut('*', '_proto') <- fixes failing test on WeaverModelQuery line 67

    super(Constructor)

module.exports = WeaverModelQuery
