cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')

class WeaverModelClass extends Weaver.Node

  constructor: (nodeId) ->
    super(nodeId)
    @className = @constructor.name

    # Add type definition to model class
    @relation("_proto").add(Weaver.Node.get(@classId()))

  classId: ->
    "#{@definition.name}:#{@className}"

  _getAttributeKey: (field) ->
    if not @classDefinition.attributes?
      throw new Error("#{@className} model is not allowed to have attributes")

    if not @classDefinition.attributes[field]?
      throw new Error("Field #{field} is not valid on this #{@className} model")

    @classDefinition.attributes[field].key or field

  _getRelationKey: (key) ->
    if not @classDefinition.relations?
      throw new Error("#{@className} model is not allowed to have relations")

    if not @classDefinition.relations[key]?
      throw new Error("Relation #{key} is not valid on this #{@className} model")

    @classDefinition.relations[key].key or key

  get: (field) ->
    super(@_getAttributeKey(field))

  set: (field, value) ->
    super(@_getAttributeKey(field), value)

  relation: (key) ->
    # Return when using a special relation like _proto
    return super(key) if ["_proto"].includes(key)

    databaseKey = @_getRelationKey(key)

    # Based on the key, construct a specific Weaver.ModelRelation
    modelKey           = key
    model              = @model
    classDefinition    = @classDefinition
    relationDefinition = @classDefinition.relations[key]
    className          = @className

    classRelation = class extends Weaver.ModelRelation
      constructor:(parent, key) ->
        super(parent, key)
        @model              = model
        @modelKey           = modelKey
        @className          = className
        @classDefinition    = classDefinition
        @relationDefinition = relationDefinition

    super(databaseKey, classRelation)

  save: (project) ->
    # TODO Check if all required fields are set
    # TODO Do something with autoincrement
    super(project)


module.exports = WeaverModelClass
