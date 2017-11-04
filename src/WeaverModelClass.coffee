cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')

class WeaverModelClass extends Weaver.Node

  constructor: (nodeId) ->
    super(nodeId)
    @className = @constructor.name

    # Add type definition to model class
    @relation("$type").add(Weaver.Node.get("#{@definition.name}:#{@className}"))

  _getAttributeKey: (field) ->
    if not @classDefinition.attributes?
      throw new Error("#{@className} model is not allowed to have attributes")

    if not @classDefinition.attributes[field]?
      throw new Error("Field #{field} is not valid on this #{@className} model")

    @classDefinition.attributes[field].key or field

  _getRelationKey: (key) ->
    # Return when using a special relation like $type
    return key if ["$type"].includes(key)

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
    super(@_getRelationKey(key), Weaver.ModelRelation)

  save: (project) ->
    # TODO Check if all required fields are set
    # TODO Do something with autoincrement
    super(project)


module.exports = WeaverModelClass
