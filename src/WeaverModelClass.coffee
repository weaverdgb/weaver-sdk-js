cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')

class WeaverModelClass extends Weaver.Node

  constructor: (nodeId) ->
    super(nodeId)
    @totalClassDefinition = @_collectFromSupers()

    # Add type definition to model class
    @relation(@getPrototypeKey()).add(Weaver.Node.get(@classId()))

  getPrototypeKey: ->
    @model.definition.prototype or '_prototype'

  getPrototype: ->
    @relation(@getPrototypeKey()).first()

  classId: ->
    "#{@definition.name}:#{@className}"

  # Returns a definition where all super definitions are collected into
  _collectFromSupers: ->
    addFromSuper = (classDefinition, totalDefinition = {attributes: {}, relations: {}}) =>

      # Start with supers so lower specifications override the super ones
      if classDefinition.super?
        superDefinition = @definition.classes[classDefinition.super]
        addFromSuper(superDefinition, totalDefinition)

      transfer = (source) ->
        totalDefinition[source][k] = v for k, v of classDefinition[source] if classDefinition[source]?

      transfer('attributes')
      transfer('relations')

      totalDefinition

    addFromSuper(@classDefinition)

  _getAttributeKey: (field) ->
    if not @totalClassDefinition.attributes?
      throw new Error("#{@className} model is not allowed to have attributes")

    if not @totalClassDefinition.attributes[field]?
      throw new Error("Field #{field} is not valid on this #{@className} model")

    @totalClassDefinition.attributes[field].key or field

  _getRelationKey: (key) ->
    if not @totalClassDefinition.relations?
      throw new Error("#{@className} model is not allowed to have relations")

    if not @totalClassDefinition.relations[key]?
      throw new Error("Relation #{key} is not valid on this #{@className} model")

    @totalClassDefinition.relations[key].key or key

  get: (field) ->
    super(@_getAttributeKey(field))

  set: (field, value) ->
    super(@_getAttributeKey(field), value)

  relation: (key) ->
    # Return when using a special relation like the prototype relation
    return super(key) if [@getPrototypeKey()].includes(key)

    databaseKey = @_getRelationKey(key)

    # Based on the key, construct a specific Weaver.ModelRelation
    modelKey             = key
    model                = @model
    relationDefinition   = @totalClassDefinition.relations[key]
    className            = @className
    definition           = @definition
    totalClassDefinition = @totalClassDefinition

    classRelation = class extends Weaver.ModelRelation
      constructor:(parent, key) ->
        super(parent, key)
        @modelKey           = modelKey
        @model              = model
        @className          = className
        @definition         = totalClassDefinition
        @relationDefinition = relationDefinition

    super(databaseKey, classRelation)

  save: (project) ->
    # Check required attributes
    for key, attribute of @totalClassDefinition.attributes when attribute.required
      if not @get(key)?
        throw new Error("Attribute #{key} is required for a #{@className} model")

    # Check cardinality on relations
    for key, relation of @totalClassDefinition.relations when relation?.card?
      [min, max] = relation.card
      current = @relation(key).all().length

      if current < min
        throw new Error("Relation #{key} requires a minimum of #{min} relations for a #{@className} model. Currently #{current} is set.")
      else if max isnt 'n' and current > max
        throw new Error("Relation #{key} allows a maximum of #{max} relations for a #{@className} model. Currently #{current} is set.")

    super(project)


module.exports = WeaverModelClass
